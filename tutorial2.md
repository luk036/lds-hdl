# 单位圆盘与球面上的低差异点：CORDIC 开平方的实现

## 概述

本教程记录了从 C++ 低差异序列库出发，将 `Disk<2,3>` 和 `Sphere<2,3>` 
转化为 Verilog 硬件模块的完整过程。核心新组件是**双曲 CORDIC 开平方**
（hyperbolic CORDIC sqrt），用于计算 `√(x)`、`√(1 − cos²φ)` 等运算。

**设计对象**：
- `Disk<2,3>` — 单位圆盘上的均匀分布点
- `Sphere<2,3>` — 单位球面上的均匀分布点

**项目仓库**：`github.com/luk036/lds-hdl`

---

## 1. 背景：Disk 和 Sphere 序列

### Disk<2,3>

从 `lds.hpp` 的 C++ 实现：

```cpp
template <unsigned long Base0 = 2, unsigned long Base1 = 3>
class Disk {
    VdCorput<Base0> vdc0;     // VdC<2> 用于角度
    VdCorput<Base1> vdc1;     // VdC<3> 用于半径

    auto pop() -> std::array<double, 2> {
        auto theta = this->vdc0.pop() * TWO_PI;
        auto radius = std::sqrt(this->vdc1.pop());
        return {radius * std::cos(theta), radius * std::sin(theta)};
    }
};
```

`Disk<2,3>` 在单位圆盘上生成均匀分布的点：
- **角度 θ**：由 `VdCorput<2>` 生成，经 `cos`/`sin` 映射到单位圆
- **半径 r**：由 `VdCorput<3>` 生成，经 `√` 变换使点在圆盘内均匀分布

如果不加 `√` 变换，点在圆盘中心会过于密集。

### Sphere<2,3>

```cpp
template <unsigned long Base0 = 2, unsigned long Base1 = 3>
class Sphere {
    VdCorput<Base0> vdcgen;   // VdC<2> 用于天顶角 φ
    Circle<Base1>   cirgen;   // Circle<3> 用于方位角 θ

    auto pop() -> std::array<double, 3> {
        auto cosphi = (2.0 * this->vdcgen.pop()) - 1.0;  // 映射到 [-1, 1]
        auto sinphi = std::sqrt(1.0 - (cosphi * cosphi));
        auto arr = this->cirgen.pop();                   // (cosθ, sinθ)
        return {sinphi * arr[0], sinphi * arr[1], cosphi};
    }
};
```

`Sphere<2,3>` 在单位球面上生成均匀分布的点：
- **天顶角 φ**：`cosφ = 2·VdC<2> − 1`（映射到 [-1, 1]），
  `sinφ = √(1 − cos²φ)`
- **方位角 θ**：由 `Circle<3>` 生成，内部使用 `VdCorput<3>` + `cos`/`sin`
- **输出点**：`(sinφ·cosθ, sinφ·sinθ, cosφ)`

---

## 2. 模块复用架构

两个新模块复用了之前已建立的基础模块：

```
Disk<2,3>
  en ──┬──► VdC<2> (vdc_16)
       │        └──► θ ──► CORDIC sin/cos (cordic_16) ──► (cosθ, sinθ)
       │                                             复用 circle_2_16
       │
       └──► VdC<3> (vdc_3_ilds) ──► 缩放 ──► √ (cordic_sqrt_16) ──► r
                                             新模块
       x = r·cosθ
       y = r·sinθ

Sphere<2,3>
  en ──┬──► VdC<2> (vdc_16) ──► cosφ = 2·VdC<2> − 1 ──┬──► z = cosφ
       │                                                │
       │                    ┌──► 1 − cos²φ ──► √ ──► sinφ ──┐
       │                    │                                │
       └──► Circle<3> (circle_3_16) ──► (cosθ, sinθ) ────┬──► x = sinφ·cosθ
                                                            │
                                                            └──► y = sinφ·sinθ
```

---

## 3. 双曲 CORDIC 开平方

### 算法原理

标准 CORDIC 算法用于圆周坐标系（计算 sin/cos），而**双曲 CORDIC**
用于双曲坐标系，可以用来计算 `√(x)`。

双曲 CORDIC 向量模式（vectoring mode，驱动 y → 0）：

```
x_{i+1} = x_i + d_i · y_i · 2⁻ⁱ
y_{i+1} = y_i + d_i · x_i · 2⁻ⁱ
```

其中 `d_i = −sign(y_i)`（向量模式）。

对于 `√(w)`，其中 `w ∈ [0, 1)`：

1. **归一化**：将 w 乘以 4 直到 w ≥ 0.25（保证收敛）
2. **初始化**：`x = w + 0.25`，`y = w − 0.25`
3. **CORDIC 迭代**：20 次迭代（迭代序列 1,2,3,4,4,5,6,...,18，重复 index 4 和 13）
4. **后处理**：`√(w) ≈ x · (1/K_h)`，其中 `K_h ≈ 0.828` 为双曲增益

### 硬件实现

```
cordic_sqrt_16 模块：

  en ──► 归一化 ──► 初始化 (x, y) ──► 20次双曲CORDIC ──► x·1/K_h ──► 反归一化 ──► √(w)

  状态机：IDLE → START (归一化+初始化) → ITER (20次) → OUTPUT → IDLE
  
  存储：20个移位参数（无atan表，无需z跟踪）
  
  内部精度：18-bit 有符号 Q2.16
  
  输出精度：16-bit U0.16，最大误差 9 LSB
```

### 与圆周 CORDIC 的关键区别

| 特性 | 圆周 CORDIC (sin/cos) | 双曲 CORDIC (sqrt) |
|------|----------------------|-------------------|
| 坐标系 | 圆周 | 双曲 |
| 角度表 | `atan(2⁻ⁱ)` | 不需要（向量模式） |
| 迭代重复 | 无 | 重复 i=4, 13 |
| 增益 K | ~1.647 | ~0.828 |
| 初始值 | `x = 1/K` | `x = w + 0.25` |
| 输出缩放 | `x >>> 2` | `x · 1/K_h >> 16` |

---

## 4. Bug 历史

### Bug #1：双曲 CORDIC 未收敛 — 缺少输入归一化

**现象**：对小值 `w < 0.25`，计算结果错误（误差高达 800 LSB）

**原因**：双曲 CORDIC 对 `w < 0.25` 收敛缓慢。因为 `w − 0.25` 的绝对值
接近 `w + 0.25`，向量在收敛前就耗尽了迭代角度范围。

**修复**：将输入乘以 4 直到 `w ≥ 0.25`，计算完后将结果除以 2^n。

### Bug #2：向量模式方向反转

**现象**：CORDIC 输出恒为 0

**原因**：向量模式应驱动 y → 0。当 `y ≥ 0` 时应**减小** y（`d = −1`），
但我的代码用了 `d = +1`（增加 y），导致向量发散而非收敛。

**修复**：`y ≥ 0 → −1，y < 0 → +1`

### Bug #3：预缩放 vs 后缩放

**现象**：开平方结果不正确（输出接近 `w + 0.25` 而非 `√(w)`）

**原因**：最初我在初始化时将 `x` 乘以 `1/K_h`，但双曲 CORDIC 的变换
是 `x_最终 = K_h · √(w)`（不是 `K_h · x_初始`）。预缩放导致
`x_最终 = K_h · (w + 0.25)/K_h = w + 0.25`，完全抵消了开平方计算。

**修复**：去掉预缩放，在后处理时乘以 `1/K_h`。

### Bug #4：16-bit 乘法截断

**现象**：`cosφ²` 在 `cosφ = −0.5` 时为 0（应为 268435456）

**原因**：Verilog 中 `$signed(a) * $signed(b)` 的表达式宽度是两个
操作数的最大宽度。16-bit × 16-bit = 16-bit，结果截断！

```verilog
// 错误：16-bit 乘法 → 结果截断
wire signed [31:0] cosphi_sq = $signed(cosphi) * $signed(cosphi);

// 正确：32-bit 乘法
wire signed [31:0] cosphi_ext = {{16{cosphi[15]}}, cosphi};
wire signed [31:0] cosphi_sq = cosphi_ext * cosphi_ext;
```

### Bug #5：饱和阈值笔误

**现象**：`√(1 − cos²φ)` 的输入始终为 65535（恒等于 1）

**原因**：阈值 `32'h3FFFFFF`（28-bit）远小于正确的 `32'h3FFFFFFF`（32-bit）
，导致所有值都被饱和截断为 65535。

```verilog
// 错误：28-bit 阈值，所有值都超过
(tmp > 32'h3FFFFFF) ? 16'd65535 : (tmp >> 14);

// 正确：32-bit 阈值
(tmp > 32'h3FFFFFFF) ? 16'd65535 : (tmp >> 14);
```

### Bug #6：状态机丢失有效信号

**现象**：第二次迭代始终超时

**原因**：`circle_valid` 和 `sqrt_valid` 信号在 `S_WAIT` 状态中捕获。
但第二次迭代的 en 脉冲到达时状态机仍在 `S_DONE`（或刚进入 `S_IDLE`），
有效信号没有被捕获。Case 语句每个周期只执行一个分支。

**修复**：将 valid 捕获移到 case 语句之前（无条件执行），
并在 `S_DONE` 中直接判断 en 以跳过 `S_IDLE`。

---

## 5. 验证结果

| 模块 | 测试数 | 通过 | 最大误差 (LSB) |
|------|--------|------|---------------|
| `cordic_sqrt_16` | 2 | 2 | 9 |
| `disk_23` | 10 | 10 | ~11 |
| `sphere_23` | 10 | 10 | x=11, y=10, z=0 |

### Sphere<2,3> 详细结果

```
idx   x        y        z        err_x err_y err_z
  1  0xc003 0x6ed2 0x0000     3    8    0  PASS
  2  0xc892 0xa007 0xc000     1    7    0  PASS
  3  0x54e2 0x473f 0x4000     9    2    0  PASS
  4  0xb079 0x1cf4 0xa000     8    1    0  PASS
  5  0x157f 0x85fc 0x2000     6    9    0  PASS
  6  0x157f 0x7a03 0xe000     6   10    0  PASS
  7  0xb079 0xe30b 0x6000     8    0    0  PASS
  8  0x2f71 0xd82d 0x9000     7    2    0  PASS
  9  0x7b88 0x1d48 0x1000    11    2    0  PASS
 10  0xae9d 0x564b 0xd000    11    4    0  PASS
```

### 误差分析

- **z 轴（cosφ）**：零误差 —— 直接从 VdC<2> 输出减 0x8000 得到
- **x/y 轴**：误差来自**三个 CORDIC 的累积**（角度 CORDIC + 圆周 CORDIC 
  + 开平方 CORDIC）+ 定点乘法截断
- 所有误差在 ±0.05% 以内（11 LSB / 32768 ≈ 0.034%）

---

## 6. 文件结构

```
lds-hdl/
├── rtl/
│   ├── vdc_16.v             # VdCorput<2> — 位反转
│   ├── vdc_3_ilds.v         # VdCorput<3> — 2²−1 技巧 + 10 整数因子
│   ├── cordic_16.v          # 圆周 CORDIC sin/cos
│   ├── cordic_sqrt_16.v     # 双曲 CORDIC 开平方（新）
│   ├── circle_2_16.v        # Circle<2> = vdc_16 + cordic_16
│   ├── circle_3_16.v        # Circle<3> = vdc_3_ilds + cordic_16
│   ├── disk_23.v            # Disk<2,3> = circle_2_16 + sqrt
│   └── sphere_23.v          # Sphere<2,3> = VdC<2> + circle_3_16 + sqrt
├── tb/                      # 测试台
└── sim/Makefile             # `make` 运行全部 88 个测试
```

---

## 7. 总结

| 模块 | 复用 | 新增 | 核心算法 |
|------|------|------|---------|
| `Disk<2,3>` | `circle_2_16` | `cordic_sqrt_16` | √(VdC<3>) |
| `Sphere<2,3>` | `circle_3_16` + `vdc_16` | `cordic_sqrt_16` | √(1 − (2·VdC<2>−1)²) |

**关键洞察**：双曲 CORDIC 开平方与圆周 CORDIC sin/cos 共享相同的基本
硬件结构（移位-加减迭代），只是迭代序列和增益常数不同。通过**输入归一化**
（乘以 4 直到 ≥ 0.25）解决了小值收敛问题，通过**后乘 1/K_h** 替代了
预缩放。

**硬件开销**：无 ROM —— 只需 20 个移位参数（~100 bits），
面积约 70 个 DFF + 组合逻辑。

*教程日期：2026-06-17*
