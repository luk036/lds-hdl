# Cocotb 验证教程：用 Python 为 Verilog 模块编写测试

## 概述

本教程以 `lds-hdl` 项目中的 32 位硬件模块为实例，完整介绍如何使用 **cocotb**（COroutine-based COsimulation TestBench）框架为 Verilog 模块编写 Python 测试。

**传统方法**：用纯 Verilog 编写测试台——计算期望值需要 clk、rst_n、en 等信号的精确时序编排，复杂数学运算在 Verilog 中极为繁琐。

**Cocotb 方法**：用 Python 编写测试，在 Python 中直接使用 `math`、`numpy` 等库计算期望值，通过协程驱动 DUT 信号，最后用 `assert` 进行断言。

**项目仓库**：`github.com/luk036/lds-hdl`

---

## 1. 为什么用 cocotb？

### 传统 Verilog 测试台的痛点

以 `lds-hdl` 中的 CORDIC 算法为例。要验证 `cordic_32` 模块对某个角度 `θ` 输出的 `cos(θ)`、`sin(θ)` 是否正确，在纯 Verilog 中你需要：

```verilog
// 在 Verilog 中计算期望值 —— 困难！
// 要么硬编码查表，要么写复杂的定点算术
reg [31:0] expected_cos [0:8];
initial begin
    expected_cos[0] = 32'h7FFFFFFF;  // cos(0)   —— 人工计算
    expected_cos[1] = 32'h00000000;  // cos(π/2) —— 人工计算
    // ... 容易出错，难以维护
end
```

### Cocotb 的优势

```python
# 在 Python 中计算期望值 —— 简单！
import math

def expected_cos_sin(angle_rad):
    c = int(round(math.cos(angle_rad) * 2**31))
    s = int(round(math.sin(angle_rad) * 2**31))
    return c, s

# 直接使用浮点运算，可读性高
test_angles = [0.0, math.pi/2, math.pi, math.pi/4]
```

| 特性 | 纯 Verilog 测试台 | Cocotb (Python) |
|------|-------------------|-----------------|
| 期望值计算 | 手工硬编码或复杂的定点运算 | `math.cos()`, `numpy` 等直接使用 |
| 复杂数据类型 | 仅支持 bit/reg/wire | 全部 Python 类型 |
| 断言 | `if/else` + `$display` | `assert`, `pytest` |
| 代码量 | 大（特别是组合模块） | 小（Python 天然简洁） |
| 调试 | 看波形 | `print()` / 日志 / 异常栈 |
| 复用 | 受限 | 函数、类、模块 |

---

## 2. 环境准备

### 安装

```bash
pip install cocotb
```

本教程使用 **cocotb 2.0.1** 和 **Icarus Verilog (iverilog)** 作为仿真器。

### 验证安装

```bash
cocotb-config --version    # 应输出 2.0.1
iverilog -V                # 应输出版本信息
```

### 项目结构

```
lds-hdl/
├── rtl/                    # Verilog 源文件
│   ├── vdc_32.v
│   ├── cordic_32.v
│   └── ...
├── cocotb/
│   ├── run.py              # 测试运行器
│   └── tests/              # Python 测试文件
│       ├── test_vdc_32.py
│       ├── test_cordic_32.py
│       └── ...
└── sim/
    └── Makefile             # 纯 Verilog 测试（传统方式）
```

---

## 3. 核心概念

### 3.1 协程与触发器

Cocotb 基于 Python `async`/`await`。测试函数必须声明为 `async`，使用触发器来控制时序。

```python
import cocotb
from cocotb.triggers import RisingEdge, FallingEdge, ClockCycles, Timer

@cocotb.test()
async def my_test(dut):
    # 等待时钟上升沿
    await RisingEdge(dut.clk)

    # 等待 5 个时钟周期
    await ClockCycles(dut.clk, 5)

    # 等待 100ns
    await Timer(100, units="ns")
```

### 3.2 时钟生成

```python
from cocotb.clock import Clock

# 创建周期为 10 个仿真时间步的时钟
cocotb.start_soon(Clock(dut.clk, 10, unit="step").start())
```

> **注意**：cocotb 2.0 中 `unit` 替代了旧版的 `units`。使用 `unit="step"` 可以避免因仿真精度设置导致的问题。

### 3.3 DUT 信号访问

Cocotb 通过 `dut.<port_name>` 访问 DUT 的所有端口：

```python
# 赋值（驱动输入端口）
dut.rst_n.value = 0       # 单个 bit
dut.en.value = 1          # 单个 bit
dut.angle.value = 0x4000  # 多 bit 总线

# 读取（从输出端口获取值）
raw = dut.vdc_out.value.integer         # 无符号整数
signed_val = dut.cos.value.signed_integer  # 有符号整数
bit_val = dut.valid.value               # 单个 bit (0/1)
```

### 3.4 日志

```python
dut._log.info("测试通过！")
dut._log.error(f"期望 0x{expected:08X}，实际 0x{got:08X}")
```

---

## 4. 第一个测试：验证 vdc_32

### DUT 介绍

`vdc_32` 是一个 van der Corput 序列生成器。每当时钟上升沿且 `en=1` 时，内部计数器加 1，输出为计数器值的**位反转**。

```verilog
module vdc_32 (
    input  wire        clk, rst_n, en,
    output wire [31:0] vdc_out,
    output reg         valid
);
```

对于 n=1：`cnt=1=0x00000001`，位反转后 `vdc_out=0x80000000`。

### 黄金模型

在 Python 中实现位反转非常简单：

```python
def bit_reverse_32(n):
    rev = 0
    x = n
    for _ in range(32):
        rev = (rev << 1) | (x & 1)
        x >>= 1
    return rev
```

### 完整测试

```python
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, ClockCycles

@cocotb.test()
async def test_vdc_32(dut):
    # 1. 启动时钟
    cocotb.start_soon(Clock(dut.clk, 10, unit="step").start())

    # 2. 复位
    dut.rst_n.value = 0
    dut.en.value = 0
    await ClockCycles(dut.clk, 5)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 2)

    # 3. 测试循环
    passed = 0
    failed = 0

    for n in range(1, 21):
        # 发送一个周期的 en 脉冲
        dut.en.value = 1
        await RisingEdge(dut.clk)
        dut.en.value = 0

        # 等待 valid 信号
        while not dut.valid.value:
            await RisingEdge(dut.clk)

        # 比较结果
        expected = bit_reverse_32(n)
        got = dut.vdc_out.value.integer
        if got == expected:
            passed += 1
        else:
            failed += 1
            dut._log.error(f"n={n}: 期望 0x{expected:08X}，实际 0x{got:08X}")

    dut._log.info(f"通过: {passed} / 失败: {failed}")
    assert failed == 0, f"{failed} 个测试失败"
```

### 时序说明

```
        ┌──┐  ┌──┐  ┌──┐  ┌──┐  ┌──┐
clk  ───┘  └──┘  └──┘  └──┘  └──┘  └──

en   ──────┐  └────────────────────
           └──┘  ← 一个周期的脉冲

valid ──────────┐  └───────────────
               └──┘  ← 下一个周期变为 1

vdc_out  ──────────< 0x80000000 >──
                    ↑ 此时读取
```

**关键点**：`valid` 是寄存器输出——它在 `en=1` 之后的**下一个**时钟上升沿才变为 1。测试必须等待 `valid` 而不是假设它立即可用。

---

## 5. 复杂测试：验证 CORDIC

### DUT 介绍

`cordic_32` 是一个 CORDIC 旋转模式模块，输入为 32 位定点角度值，输出为 `cos(θ)` 和 `sin(θ)` 的 32 位 Q1.31 定点值。

```verilog
module cordic_32 (
    input  wire        clk, rst_n, en,
    input  wire [31:0] angle,   // 0 = 0°, 2^32 = 360°
    output reg  [31:0] cos, sin,
    output reg         valid
);
```

CORDIC 算法需要 **31 个时钟周期**来完成计算——测试必须等待 `valid=1` 才能读取结果。

### 黄金模型

```python
import math

def angle_to_cordic_input(angle_rad):
    """将弧度转换为 CORDIC 的 32 位定点输入格式"""
    return int(round(angle_rad / (2 * math.pi) * 2**32)) & 0xFFFFFFFF

def expected_cos_sin(angle_rad):
    """计算期望的 cos/sin 值（Q1.31 定点格式）"""
    c = int(round(math.cos(angle_rad) * 2**31))
    s = int(round(math.sin(angle_rad) * 2**31))
    # 钳位到 32 位有符号范围
    if c >= 2**31: c = 2**31 - 1
    if c < -2**31: c = -2**31
    if s >= 2**31: s = 2**31 - 1
    if s < -2**31: s = -2**31
    return c & 0xFFFFFFFF, s & 0xFFFFFFFF
```

### 完整测试

```python
@cocotb.test()
async def test_cordic_32(dut):
    cocotb.start_soon(Clock(dut.clk, 10, unit="step").start())

    # 复位
    dut.rst_n.value = 0
    dut.en.value = 0
    dut.angle.value = 0
    await ClockCycles(dut.clk, 3)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)

    passed = 0
    failed = 0
    threshold = 50000  # 误差容忍度（约 0.0025%）

    test_angles = [
        0.0, math.pi/2, math.pi,           # 0°, 90°, 180°
        math.pi/4, math.pi/8,               # 45°, 22.5°
        3*math.pi/4, 5*math.pi/4,           # 135°, 225°
        7*math.pi/4, math.pi/16,            # 315°, 11.25°
    ]

    for angle_rad in test_angles:
        # 设置角度并发送 en 脉冲
        dut.angle.value = angle_to_cordic_input(angle_rad)
        dut.en.value = 1
        await RisingEdge(dut.clk)
        dut.en.value = 0

        # 等待 CORDIC 完成（最多 40 个周期）
        for _ in range(40):
            await RisingEdge(dut.clk)
            if dut.valid.value:
                # 读取结果
                exp_cos, exp_sin = expected_cos_sin(angle_rad)
                got_cos = dut.cos.value.signed_integer
                got_sin = dut.sin.value.signed_integer

                # 计算误差
                err_c = abs(got_cos - (exp_cos if exp_cos < 2**31
                                       else exp_cos - 2**32))
                err_s = abs(got_sin - (exp_sin if exp_sin < 2**31
                                       else exp_sin - 2**32))

                if err_c < threshold and err_s < threshold:
                    passed += 1
                else:
                    failed += 1
                    dut._log.error(
                        f"θ={angle_rad:.4f}: cos 误差={err_c}, sin 误差={err_s}"
                    )
                break  # 跳出等待循环

    dut._log.info(f"通过: {passed} / 失败: {failed}")
    assert failed == 0, f"{failed} 个测试失败"
```

### 定点数注意事项

CORDIC 输出的 `cos`/`sin` 是 Q1.31 格式。32 位中：最高位（bit 31）为符号位，bit 30-0 为小数部分。

```python
# 读取时使用 signed_integer
got_cos = dut.cos.value.signed_integer  # Python int，范围 [-2^31, 2^31-1]

# 期望值从浮点转换（需小心处理边界）
# 0x7FFFFFFF = 最大正数 ≈ cos(0) = 1.0
# 0x80000000 = 最负数 ≈ cos(π) = -1.0
```

> **常见陷阱**：对于 32 位宽的有符号端口，某些 cocotb/iverilog 组合在读取 `signed_integer` 时可能出现问题。如果遇到大的异常误差，先用 `integer`（无符号）读取，再手动做符号转换来排查。

---

## 6. 多模块组合测试

### 验证 disk_32

`disk_32` 是一个组合模块，内部实例化了三个子模块：

```
disk_32
  ├── circle_2_32  (vdc_32 + cordic_32)  → (cosθ, sinθ)
  ├── vdc_3_ilds_32                       → raw
  └── cordic_sqrt_32                      → √(raw)
                                           → (r·cosθ, r·sinθ)
```

由于硬件模块有固定的延迟周期，测试需要等待所有子流水线完成。

```python
@cocotb.test()
async def test_disk_32(dut):
    cocotb.start_soon(Clock(dut.clk, 10, unit="step").start())

    dut.rst_n.value = 0
    dut.en.value = 0
    await ClockCycles(dut.clk, 3)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)

    passed = 0
    failed = 0

    for n in range(1, 11):
        dut.en.value = 1
        await RisingEdge(dut.clk)
        dut.en.value = 0

        # disk_32 需要最多 100 个周期完成
        for _ in range(100):
            await RisingEdge(dut.clk)
            if dut.valid.value:
                x = dut.x.value.signed_integer
                y = dut.y.value.signed_integer

                # 检查：点必须在单位圆盘内 (x² + y² ≤ 1)
                mag_sq = (x * x + y * y) >> 30
                if mag_sq <= 4 * 2**30:
                    passed += 1
                else:
                    failed += 1
                    dut._log.error(
                        f"n={n}: x=0x{x:08X}, y=0x{y:08X}, 超出范围"
                    )
                break

    dut._log.info(f"通过: {passed} / 失败: {failed}")
    assert failed == 0
```

### 不变量检查 vs 精确值比较

对于复杂组合模块，有时不**需要**逐位精确匹配。更好的策略是验证**数学不变量**：

| 模块 | 不变量 |
|------|--------|
| `circle_2_32` | `cos²θ + sin²θ ≈ 1` |
| `sphere_32` | `x² + y² + z² ≈ 1` |
| `disk_32` | `x² + y² ≤ 1` |
| `cordic_sqrt_32` | `(√x)² ≈ x` |

这种方式对 CORDIC 的累积误差更具鲁棒性。

---

## 7. 测试运行器

### Python Runner（推荐）

Cocotb 2.0 提供了 `cocotb_tools.runner` 模块，无需 Makefile 即可运行测试：

```python
from cocotb_tools.runner import get_runner

runner = get_runner("icarus")

# 编译
runner.build(
    sources=["../rtl/vdc_32.v"],
    hdl_toplevel="vdc_32",
    build_dir="sim_build_vdc_32",
)

# 运行测试
runner.test(
    hdl_toplevel="vdc_32",
    test_module="test_vdc_32",
    test_dir="tests",
    build_dir="sim_build_vdc_32",
)
```

### 完整 Runner 示例

```python
MODULES = {
    "vdc_32": (
        "vdc_32", [RTL / "vdc_32.v"], "test_vdc_32"
    ),
    "cordic_32": (
        "cordic_32", [RTL / "cordic_32.v"], "test_cordic_32"
    ),
    "circle_2_32": (
        "circle_2_32",
        [RTL / f for f in ["circle_2_32.v", "vdc_32.v", "cordic_32.v"]],
        "test_circle_2_32",
    ),
    # ... 更多模块
}

for name, (toplevel, sources, test_module) in MODULES.items():
    runner.build(
        sources=[str(s) for s in sources],
        hdl_toplevel=toplevel,
        build_dir=f"sim_build_{name}",
    )
    runner.test(
        hdl_toplevel=toplevel,
        test_module=test_module,
        test_dir="tests",
        build_dir=f"sim_build_{name}",
    )
```

### 结果检查

Cocotb 自动生成 `results.xml`（JUnit 格式）。可以用以下代码解析：

```python
import xml.etree.ElementTree as ET

tree = ET.parse("sim_build_vdc_32/results.xml")
for ts in tree.getroot().findall("testsuite"):
    failures = int(ts.get("failures", "0"))
    errors = int(ts.get("errors", "0"))
    if failures == 0 and errors == 0:
        print("PASSED")
    else:
        print(f"FAILED: {failures} 失败, {errors} 错误")
```

---

## 8. 常见问题与调试

### 问题 1：`valid` 时序

**现象**：测试读取的输出值总是不对（看起来落后一个周期）。

**原因**：`valid` 是寄存器输出，在 `en` 脉冲之后的下一个时钟沿才有效。

**修复**：在 `en` 脉冲之后显式等待 `valid`：

```python
dut.en.value = 1
await RisingEdge(dut.clk)
dut.en.value = 0
while not dut.valid.value:     # 等待而非假设
    await RisingEdge(dut.clk)
```

### 问题 2：`signed_integer` 读取异常

**现象**：对于 32 位有符号端口，`dut.port.value.signed_integer` 返回的值与预期相差甚远。

**原因**：某些 iverilog 版本在 VPI 层面对宽有符号值的处理有问题。

**解决方案**：
1. 先用 `.integer` 读取无符号值
2. 手动转换为有符号：

```python
raw = dut.cos.value.integer
got_cos = raw if raw < 2**31 else raw - 2**32
```

### 问题 3：`Clock` 参数

**现象**：`ValueError: Bad period: Unable to accurately represent 10(ns)...`

**原因**：仿真精度与时间单位不匹配。

**修复**：使用 `unit="step"` 作为时钟周期单位，或添加 `timescale 指令。

```python
# 推荐：避免时间单位问题
cocotb.start_soon(Clock(dut.clk, 10, unit="step").start())
```

### 问题 4：Windows 环境

Cocotb 的 Makefile 系统依赖 `bash`、`uname` 等 Unix 工具。在 Windows 上：

- **推荐**：使用 WSL2 或 MSYS2
- **替代**：使用 Python Runner（`cocotb_tools.runner`）替代 Makefile
- **Git Bash**：在 Git Bash 中运行 cocotb Makefile 通常可行

---

## 9. 与纯 Verilog 测试台的对比

以 `lds-hdl` 项目为例：

| 方面 | 纯 Verilog (`tb/`) | Cocotb (`cocotb/tests/`) |
|------|-------------------|-------------------------|
| 期望值计算 | 硬编码 16 进制常量 | `math.cos()`, Python 函数 |
| 测试长度 | 51-183 行/文件 | 43-75 行/文件 |
| 可维护性 | 改一个期望值要重新编译 | 改即运行 |
| 复杂数学 | 需手工推导定点表示 | `round(value * 2**31)` |
| 依赖 | 仅需 iverilog | 需 Python + cocotb |
| 并行测试 | 需 Makefile | `python run.py` 一键运行 |

**推荐策略**：基础模块用纯 Verilog 测试（零额外依赖，速度快）；算法密集型模块用 cocotb（数学计算方便，期望值自动生成）。

---

## 10. 文件结构总览

```
lds-hdl/
├── rtl/                        # Verilog RTL 设计
│   ├── vdc_32.v
│   ├── cordic_32.v
│   ├── cordic_sqrt_32.v
│   ├── vdc_3_ilds_32.v
│   ├── circle_2_32.v
│   ├── circle_3_32.v
│   ├── disk_32.v
│   └── sphere_32.v
├── tb/                         # 纯 Verilog 测试台
│   ├── tb_vdc_32.v
│   └── ...
├── cocotb/
│   ├── run.py                  # Python 测试运行器
│   │                           #   用法: python run.py [模块名]
│   └── tests/
│       ├── test_vdc_32.py      # VdCorput<2> 测试
│       ├── test_vdc_3_ilds_32.py
│       ├── test_cordic_32.py   # CORDIC 测试（含黄金模型）
│       ├── test_cordic_sqrt_32.py
│       ├── test_circle_2_32.py
│       ├── test_circle_3_32.py
│       ├── test_disk_32.py     # 组合模块（不变量检查）
│       └── test_sphere_32.py
└── sim/
    └── Makefile                 # 纯 Verilog 测试编译
```

### 运行命令

```bash
# 运行全部 cocotb 测试
cd cocotb
python run.py

# 运行单个模块
python run.py vdc_32
python run.py cordic_32

# 运行纯 Verilog 测试（传统方式）
cd sim
make all32
```

---

## 总结

| 阶段 | 工具 | 产出 |
|------|------|------|
| 硬件设计 | Verilog | 32 位定点 RTL 模块 |
| 黄金模型 | Python + `math` | 浮点精度期望值计算 |
| 测试编写 | Cocotb | Python 协程测试脚本 |
| 仿真运行 | Icarus + cocotb runner | JUnit XML 结果 |
| 传统验证 | 纯 Verilog 测试台 | 独立零依赖测试 |

**核心洞察**：Cocotb 让硬件验证从"用 Verilog 写测试"变成了"用 Python 写测试"。对于涉及浮点运算、数学函数的模块（如 CORDIC），Python 的 `math` 库直接可用，避免了在 Verilog 中手工推导定点表示的繁琐工作。组合模块则可以用数学不变量（如 `x²+y²+z²≈1`）来验证，比逐位精确匹配更具工程意义。

*教程日期：2026-06-17 &nbsp;|&nbsp; 项目：github.com/luk036/lds-hdl*
