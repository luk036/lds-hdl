# van der Corput 序列的硬件设计：从 C++ 到 Verilog 综合

## 概述

本教程完整记录了一个低差异序列（Low Discrepancy Sequence, LDS）硬件模块的设计流程：从 C++ 参考实现出发，转化为 Verilog RTL，编写测试台验证，最终使用 Yosys 进行逻辑综合并输出 JSON 网表。

**设计对象**：`VdCorput<2>` — 基数为 2 的 van der Corput 序列生成器，16 位输出精度。

**项目仓库**：`github.com/luk036/lds-hdl`

---

## 1. 背景：什么是 van der Corput 序列？

van der Corput 序列是一类低差异序列，广泛用于拟蒙特卡洛方法（Quasi-Monte Carlo）。它通过在基数 b 下反转正整数索引的数字来生成 [0, 1) 区间内的点。

### 基数为 2 的情况

最简单的形式是基数为 2（二进制）。对索引 n，将 n 的二进制表示按位反转，解释为二进制小数：

```
n (dec) | n (binary) | reversed | VdC(n)  | 16-bit hex
--------+------------+----------+---------+-----------
   1    |       0001 |     1000 | 0.5     | 0x8000
   2    |       0010 |     0100 | 0.25    | 0x4000
   3    |       0011 |     1100 | 0.75    | 0xC000
   4    |       0100 |     0010 | 0.125   | 0x2000
   5    |       0101 |     1010 | 0.625   | 0xA000
   6    |       0110 |     0110 | 0.375   | 0x6000
   7    |       0111 |     1110 | 0.875   | 0xE000
   8    |       1000 |     0001 | 0.0625  | 0x1000
```

**关键发现**：在基数为 2 时，"按位反转"正是算法的全部——不需要除法、求模或乘法。这使得硬件实现极简。

---

## 2. C++ 参考实现

`lds-cpp` 项目提供了模板化的高性能实现。核心算法在 `include/lds/lds.hpp` 中：

### 自由函数版本

```cpp
template <unsigned long Base = 2>
constexpr auto vdc(unsigned long cnt) -> double {
    auto reslt = 0.0;
    auto denom = 1.0;
    auto count = cnt;
    while (count != 0) {
        const auto remainder = count % Base;
        count /= Base;
        denom *= double(Base);
        reslt += double(remainder) / denom;
    }
    return reslt;
}
```

### 类版本（带状态）

```cpp
template <unsigned long Base = 2>
class VdCorput {
    unsigned long count{0};
    std::array<double, MAX_REVERSE_BITS> rev_lst{};

public:
    constexpr VdCorput() {
        double reverse = 1.0;
        for (unsigned long i = 0; i < MAX_REVERSE_BITS; ++i) {
            reverse /= double(Base);
            this->rev_lst[i] = reverse;
        }
    }

    constexpr auto pop() -> double {
        unsigned long count_value = ++this->count;
        unsigned long idx = 0;
        double res = 0.0;
        while (count_value != 0) {
            const auto remainder = count_value % Base;
            count_value /= Base;
            res += this->rev_lst[idx] * double(remainder);
            ++idx;
        }
        return res;
    }
};
```

对于 Base=2，每次迭代等价于"取 LSB → 右移一位 → 权重累加"。

---

## 3. Verilog RTL 实现

基于"基 2 = 按位反转"的观察，硬件实现极为简洁：

```verilog
module vdc_16 (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       en,
    output wire [15:0] vdc_out,
    output reg        valid
);

    reg [15:0] cnt;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt    <= 16'd0;
            valid  <= 1'b0;
        end else if (en) begin
            cnt    <= cnt + 16'd1;
            valid  <= 1'b1;
        end else begin
            valid  <= 1'b0;
        end
    end

    // 核心：按位反转 = VdC 基 2 的全部计算
    assign vdc_out = {
        cnt[ 0], cnt[ 1], cnt[ 2], cnt[ 3],
        cnt[ 4], cnt[ 5], cnt[ 6], cnt[ 7],
        cnt[ 8], cnt[ 9], cnt[10], cnt[11],
        cnt[12], cnt[13], cnt[14], cnt[15]
    };

endmodule
```

### 设计要点

- **无面积开销**：`vdc_out` 仅是计数器比特的重新连线（wire permutation），在 FPGA 上消耗零逻辑资源，在 ASIC 上只需金属层布线。
- **16 位计数器**：输出精度 16 位意味着每 65536 个时钟周期完成一个完整周期。
- **异步复位**：`rst_n` 低电平有效，将计数器清零。
- **使能信号**：`en` 控制序列推进，便于外部节流控制。

---

## 4. 测试台与验证

使用 Icarus Verilog (iverilog) 进行功能验证。测试台生成前 20 个序列值并与预期值对比：

### 预期值

计算方式：`expected[i] = bit_reverse(i, 16)`，对应 C++ 参考的 `vdc<2>(i) * 2^16`。

```verilog
localparam integer N_EXPECTED = 20;
reg [15:0] expected [0:N_EXPECTED-1];

initial begin
    expected[ 0] = 16'h8000;   // n=1:  0.5
    expected[ 1] = 16'h4000;   // n=2:  0.25
    expected[ 2] = 16'hC000;   // n=3:  0.75
    expected[ 3] = 16'h2000;   // n=4:  0.125
    expected[ 4] = 16'hA000;   // n=5:  0.625
    // ... (到 n=20)
end
```

### 验证结果

```
------------------------------------------------------------
  VdCorput<2>  16-bit  Verification
------------------------------------------------------------
  idx   expected    got       VdC(float)  pass/fail
------------------------------------------------------------
   1 | 0x8000  | 0x8000 | 0.500000  PASS
   2 | 0x4000  | 0x4000 | 0.250000  PASS
   3 | 0xc000  | 0xc000 | 0.750000  PASS
   4 | 0x2000  | 0x2000 | 0.125000  PASS
   5 | 0xa000  | 0xa000 | 0.625000  PASS
   ... (共 20 项)
------------------------------------------------------------
  Passed: 20  /  Failed: 0
------------------------------------------------------------
  *** ALL TESTS PASSED ***
------------------------------------------------------------
```

### 运行命令

```bash
cd sim
make          # 或直接：
iverilog -g2012 -o build/tb_vdc_16 ../tb/tb_vdc_16.v ../rtl/vdc_16.v
vvp build/tb_vdc_16
```

---

## 5. Yosys 逻辑综合

### 技术库

`tutorial_tech.lib` 是一个 Yosys 格式的 Liberty 库，包含：

| 单元名 | 逻辑功能 |
|--------|----------|
| `_dollar__AND_` | AND 门 |
| `_dollar__OR_` | OR 门 |
| `_dollar__XOR_` | XOR 门 |
| `_dollar__NOT_` | 非门（函数定义为 `(A)`，实际为缓冲器） |
| `_dollar__MUX_` | 2 选 1 多路选择器 |
| `_dollar__DFF_P_` | 上升沿 D 触发器 |
| `_dollar__DFF_N_` | 下降沿 D 触发器 |
| `_dollar__DLATCH_P_` | 高电平透明锁存器 |

### 综合流程

```
Yosys 流程：
  read_liberty -lib tutorial_tech.lib     # 读入库
  read_verilog rtl/vdc_16.v               # 读入 RTL
  hierarchy -top vdc_16                   # 展开层次
  synth -top vdc_16                       # 粗粒度综合
  dfflibmap -liberty tutorial_tech.lib    # 映射触发器
  abc -liberty tutorial_tech.lib          # 映射组合逻辑
  stat                                     # 统计报告
  write_verilog vdc_16_synth.v            # 输出网表
  write_json vdc_16_synth.json            # 输出 JSON 网表
```

### 综合结果

粗粒度综合（`synth` 阶段）完成后，网表包含 **72 个标准单元**：

| 单元类型 | 数量 | 用途 |
|----------|------|------|
| `$_DFF_PN0_` | 17 | 16 位计数器 + valid 标志 |
| `$_MUX_` | 15 | 计数器递增使能逻辑 |
| `$_NAND_` | 7 | 行波进位传播链 |
| `$_NOR_` | 2 | 行波进位传播链 |
| `$_ORNOT_` | 11 | 行波进位传播链 |
| `$_OR_` | 4 | 行波进位传播链 |
| `$_XNOR_` | 14 | 行波进位传播链 |
| `$_XOR_` | 2 | 行波进位传播链 |

**关键发现**：按位反转操作消耗了 **零个逻辑单元**——它仅仅是网表中的连线重排。

### 库映射的问题

`dfflibmap` 和 `abc` 两个阶段未能将设计完全映射到 `tutorial_tech.lib`，原因有二：

1. **触发器缺少异步复位**：库中只有无复位的简单 DFF，而我们的设计使用异步复位触发器。库需要添加带复位引脚的 DFF 单元。
2. **NOT 单元函数错误**：`_dollar__NOT_` 的函数定义为 `(A)`（缓冲器）而非 `(!A)`（反相器）。ABC 需要识别反相器才能进行技术映射。这导致 ABC 在 `sclLibUtil.c:911` 处断言失败。

这两点在教程库中留作练习，读者可尝试修复后重新运行综合。

---

## 6. JSON 网表输出与验证

Yosys 的 `write_json` 命令生成结构化 JSON 网表，遵循 Yosys Netlist JSON Schema：

```bash
yosys -s synth_vdc_16.ys    # 包含 write_json vdc_16_synth.json
```

生成的 JSON 包含：

```json
{
  "creator": "Yosys 0.9+2406",
  "modules": {
    "vdc_16": {
      "ports": { "clk": "input", "rst_n": "input", ... },
      "cells": { ... },
      "netnames": { ... }
    }
  }
}
```

验证流程使用 `validate_yosys_json.py`：

```python
from jsonschema import validate
from netlistx.netlist import read_yosys_json

with open("yosys_schema.json") as f:
    schema = json.load(f)
with open("synth/vdc_16_synth.json") as f:
    data = json.load(f)

validate(instance=data, schema=schema)              # 模式验证
netlist = read_yosys_json("synth/vdc_16_synth.json")  # 网表加载
```

输出：
```
Validating against yosys_schema.json...
*** SCHEMA VALIDATION PASSED ***

Testing read_yosys_json() function...
Successfully loaded netlist from synth/vdc_16_synth.json
  Modules: 3
  Nets: 3
  Total nodes: 6
  Pins (edges): 3
  Pads (I/O ports): 3
```

---

## 7. 综合网表的功能验证

综合后的网表（`vdc_16_synth.v`）使用 Yosys 内部 `$_*` 单元，需配合 Yosys 的 `simlib.v` 仿真库进行验证：

```bash
iverilog -g2012 -o synth_test \
    tb/tb_vdc_16.v \
    synth/vdc_16_synth.v \
    /path/to/yosys/share/simlib.v
vvp synth_test
```

结果与 RTL 仿真完全一致：**20/20 PASS**。这证明综合过程正确保持了功能。

---

## 8. 工程结构总览

```
lds-hdl/
├── rtl/
│   └── vdc_16.v              # Verilog RTL 设计
├── tb/
│   └── tb_vdc_16.v           # 测试台
├── sim/
│   └── Makefile               # iverilog 编译脚本
├── synth/
│   ├── synth_vdc_16.ys        # Yosys 综合脚本
│   ├── vdc_16_synth.v         # 综合后网表 (Yosys 内部单元)
│   ├── vdc_16_synth.json      # JSON 格式网表
│   └── vdc_16_area.rpt        # 面积/单元统计报告
├── tutorial_tech.lib          # 技术库 (Liberty 格式)
├── yosys_schema.json          # Yosys JSON 模式定义
└── validate_yosys_json.py     # JSON 验证与网表加载示例
```

---

## 9. 总结

本教程展示了从算法到硬件的完整设计流程：

| 阶段 | 工具 | 成果 |
|------|------|------|
| 算法参考 | C++ (lds-cpp) | `VdCorput<2>` 模板实现 |
| 硬件描述 | Verilog | `vdc_16.v` — 16 位序列生成器 |
| 功能验证 | iverilog | 20/20 测试通过 |
| 逻辑综合 | Yosys 0.9 | 72 单元网表，零面积位反转 |
| JSON 验证 | jsonschema + netlistx | JSON 模式验证通过 |

**核心洞察**：van der Corput 序列在基数为 2 时退化为纯粹的按位反转操作，在硬件中只需连线无需逻辑门，使其成为极低开销的硬件随机数发生器——非常适合 FPGA 和 ASIC 中的拟蒙特卡洛加速。

---

*教程日期：2026-06-17 &nbsp;|&nbsp; 项目：github.com/luk036/lds-hdl*
