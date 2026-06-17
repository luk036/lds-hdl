# Circle Sequence Generator with CORDIC — Implementation Report

## Overview

This report documents the design, implementation, and verification of hardware
Circle sequence generators (`Circle<2>`, `Circle<3>`) that produce evenly
distributed points on the unit circle using two techniques:

- **van der Corput sequence** (`VdCorput`): generates low-discrepancy angles
- **CORDIC algorithm**: computes sin/cos of the angle without multipliers or
  lookup tables

The key challenge was getting the fixed-point CORDIC to converge correctly — a
process that uncovered several subtle Verilog and fixed-point arithmetic bugs.

---

## 1. Architecture

```
                          ┌──────────────────────┐
en ─────────────────────► │ VdCorput Generator    │
                          │ (vdc_16 / vdc_3_ilds)│
                          │                      │
                          │ raw / angle  [15:0]  │
                          │ valid                 │
                          └──────────┬───────────┘
                                     │
                                     ▼ angle
                          ┌──────────────────────┐
                          │ CORDIC sin/cos       │
                          │ (cordic_16)          │
                          │ 16 iterations        │
                          │ 18-bit signed        │
                          │ Q1.17 internal       │
                          │ Q1.15 output         │
                          │                      │
                          │ cos [15:0]  sin [15:0]│
                          │ valid                 │
                          └──────────────────────┘
```

### Data flow

1. External `en` triggers the VdC generator
2. VdC outputs a 16-bit angle (0 = 0, 0x8000 = π, 0xFFFF ≈ 2π)
3. CORDIC starts when VdC `valid` fires
4. After 16 clock cycles, CORDIC outputs (cos, sin) in Q1.15 format

### Key design parameters

| Parameter | Value |
|-----------|-------|
| Internal bit width | 18-bit signed (Q1.17) |
| CORDIC iterations | 16 |
| Output format | 16-bit Q1.15 (signed, [-1, 1)) |
| Area (synthesized) | ~70 DFFs + combinational |
| ROM size | **0** — atan table is 16×16 = 256 bits |
| Latency | 17 cycles per point |
| Precision | ±6 LSBs max error (≈0.02% of full scale) |

---

## 2. CORDIC Algorithm

### Standard rotation-mode CORDIC

For rotation by angle z₀:
```
x₀ = 1/K    (K ≈ 1.64676, the CORDIC gain)
y₀ = 0
z₀ = target angle in [-π/2, π/2]

for i = 0 to N-1:
    d = sign(zᵢ)   // +1 for CCW, -1 for CW
    xᵢ₊₁ = xᵢ - d·yᵢ·2⁻ⁱ
    yᵢ₊₁ = yᵢ + d·xᵢ·2⁻ⁱ
    zᵢ₊₁ = zᵢ - d·atan(2⁻ⁱ)
```

After N iterations: `(x, y) ≈ (cos(z₀), sin(z₀))` scaled by the gain K,
which is cancelled by the initial 1/K pre-scaling.

### Angle format

The input angle is a 16-bit binary angle where:
```
0x0000 = 0         rad
0x4000 = π/2
0x8000 = π
0xC000 = 3π/2
0xFFFF ≈ 2π - ε
```

### Quadrant reduction

The full [0, 2π) range is reduced to [0, π/2] using symmetry:

| Quadrant | Angle range | Reduced z | cos sign | sin sign |
|----------|-------------|-----------|----------|----------|
| Q1 (00) | [0, π/2) | angle[13:0] | + | + |
| Q2 (01) | [π/2, π) | π/2 - sub | − | + |
| Q3 (10) | [π, 3π/2) | angle[13:0] | − | − |
| Q4 (11) | [3π/2, 2π) | π/2 - sub | + | − |

Where `sub = angle[13:0]` and `π/2 - sub` is computed as `0x4000 - sub`.

### Atan table (14-bit angle format, 0x4000 = π/2)

| i | atan(2⁻ⁱ) | Value | Notes |
|---|-----------|-------|-------|
| 0 | atan(1) | 8192 | π/4 |
| 1 | atan(½) | 4836 | ~26.6° |
| 2 | atan(¼) | 2555 | ~14.0° |
| 3 | atan(⅛) | 1297 | ~7.1° |
| 4 | atan(¹⁄₁₆) | 651 | ~3.6° |
| 5-15 | ... | ... | converges to 0 |

### Initial X constant

```
K = ∏ᵢ₌₀¹⁵ √(1 + 2⁻²ⁱ) ≈ 1.646760258
XI = round((2¹⁷ − 1) / K) = 79589
```

This is the pre-scaling factor `1/K` in Q1.17 format. After 16 CORDIC
iterations, `x` grows to `K × XI ≈ 2¹⁷ − 1` (the max Q1.17 value).

### Output scaling

Internal Q1.17 → output Q1.15: `out = x >>> 2` (shift right by 2, with
sign extension, then optional negation per quadrant).

---

## 3. Bug History

### Bug #1: Unsigned reg for x, y

**Symptom**: CORDIC output amplitude ~15% too low for all angles.

**Root cause**: `reg [17:0] x, y` is unsigned. Verilog's `>>>` behaves as
logical shift for unsigned types. When x becomes negative during CORDIC
iterations, `x >>> i` zero-fills instead of sign-extending, corrupting the
computation.

**Fix**: `reg signed [17:0] x, y`

**Lesson**: Always use `reg signed` for datapaths that can go negative,
even if initial values are positive.

### Bug #2: 14-bit truncation in angle reduction

**Symptom**: Quadrant 2 and 4 angles gave wrong results when the reduced
angle was exactly π/2 (0x4000).

**Root cause**:
```verilog
z <= {2'b00, 16'h4000 - angle[13:0]};
```
The expression `16'h4000 - 0` = `0x4000 = 16384`. But `{2'b00, value[13:0]}`
extracts only the low 14 bits: `0x4000[13:0] = 0x0000`. Result: z = 0 instead
of z = π/2.

**Fix**: Remove the `{2'b00, ...}` wrapper for Q2 and Q4:
```verilog
z <= 16'h4000 - {2'b00, angle[13:0]};   // full 16-bit result
```

**Lesson**: When the reduced angle can be π/2 (0x4000 = 15 bits), don't
truncate to 14 bits.

### Bug #3: Python simulation used sequential instead of parallel update

**Symptom**: Python fixed-point simulation showed identical wrong outputs
as the Verilog CORDIC (implied the algorithm itself was wrong).

**Root cause**:
```python
x -= (y >> i)
y += (x >> i)   # Uses the UPDATED x, not the original!
```
CORDIC requires BOTH x and y to use their ORIGINAL values. Python's
sequential `=` is wrong; Verilog's NBA `<=` is correct.

**Fix**:
```python
xn = x - (y >> i)
yn = y + (x >> i)   # Uses original x, not xn
x, y = xn, yn
```

After fixing, the Python simulation showed **max ±5 LSB error** for 16-bit
Q1.15 output — confirming the algorithm was correct all along.

**Lesson**: Never use sequential assignment for CORDIC iterations in
simulation. Always compute both x and y from the original values.

### Bug #4: Posedge race condition in testbench

**Symptom**: Circle<2> test showed VdC counter incrementing by 2 (not 1)
per iteration, causing wrong angles for n ≥ 2.

**Root cause**: The testbench loop:
```verilog
wait(valid);           // level-sensitive, unblocks when valid=1
#1;                    // settle
$display(...);
@(posedge clk);        // ← fires IMMEDIATELY because current posedge
                       //   is the same one that set valid=1!
```
`@(posedge clk)` after `wait(valid)` does NOT wait for the next clock
edge — it fires immediately because the posedge already occurred. This
causes the next loop iteration to start on the same cycle, giving vdc_16
an extra enable.

**Fix**: Use `@(negedge clk)` instead:
```verilog
@(posedge valid);      // edge-triggered on CORDIC completion
#1;
$display(...);
@(negedge clk);        // wait for NEGEDGE (past the triggering posedge)
```

**Lesson**: Never use `@(posedge clk)` after an event that was triggered
by the same clock edge. Use `@(negedge clk)` or `#1` to advance past it.

### Bug #5: Unsigned error comparison

**Symptom**: sin=0xFFFF (which is -1 in signed, i.e., ≈ 0) compared against
expected 0x0000 gave error 65535 instead of 1.

**Root cause**: `(sin > expected) ? sin - expected : expected - sin`
treats Q1.15 values as unsigned. 0xFFFF = 65535 unsigned, but -1 signed.

**Fix**: Use signed comparison:
```verilog
err = $signed(got) - $signed(expected);
if (err < 0) err = -err;
```

---

## 4. Results

### Verification summary

| Module | Tests | Pass | Max error |
|--------|-------|------|-----------|
| `vdc_16.v` | 20 | 20 | exact (bit-reversal) |
| `vdc_3_ilds.v` | 12 | 12 | exact (integer factors) |
| `vdc_7_ilds.v` | 12 | 12 | exact (integer factors) |
| `circle_2_16.v` | 12 | 12 | 5 LSBs |
| `circle_3_16.v` | 12 | 12 | 6 LSBs |

### CORDIC precision

For 16-bit Q1.15 output with 16 CORDIC iterations:

| Angle | cos error (LSB) | sin error (LSB) |
|-------|----------------|-----------------|
| 0 | 3 | 1 |
| π/2 | 3 | 2 |
| π | 3 | 3 |
| 3π/2 | 3 | 3 |
| π/4 | 4 | 1 |
| Max (all 12 angles) | 5 | 3 |

All errors are within theoretical bounds for 16-iteration CORDIC
(≈ 2⁻¹⁵ ≈ 1 LSB residual angular error, plus truncation noise).

### Resource usage (no ROM)

- Atan table: 16 × 16 = 256 bits
- Initial X: 1 × 18 = 18 bits  
- Datapath: 4 × 18 = 72 bits (x, y, x_next, y_next)
- Angle: 16 bits
- Control: ~12 bits (iter, quad, flags)
- Total storage: **~374 bits** — no ROM, no large tables

---

## 5. Files

```
lds-hdl/
├── rtl/
│   ├── vdc_16.v           # VdCorput<2> — bit-reversal (zero logic)
│   ├── vdc_3_ilds.v       # VdCorput<3> — 2^2-1 trick + 10 integer factors
│   ├── vdc_7_ilds.v       # VdCorput<7> — 2^3-1 trick + 5 integer factors
│   ├── cordic_16.v        # CORDIC sin/cos — 16 iterations, 18-bit signed
│   ├── circle_2_16.v      # Circle<2> = vdc_16 + cordic_16
│   └── circle_3_16.v      # Circle<3> = vdc_3_ilds + angle_scale + cordic_16
├── tb/                    # Testbenches (all pass)
├── sim/Makefile           # `make` runs all tests
├── scripts/gen_vdc_rom.py # ROM generator (reference only)
└── notes1.md              # This file
```

---

## 6. References

- J. E. Volder, "The CORDIC Trigonometric Computing Technique", IRE Trans.
  Electronic Computers, 1959.
- R. Andraka, "A survey of CORDIC algorithms for FPGA based computers",
  FPGA '98.
- Ray Andraka, "CORDIC FAQ", http://www.andraka.com/cordic.htm
- Ettus Research, USRP CORDIC implementation (Verilog),
  `fpga/usrp1/sdr_lib/cordic.v`

---

*Report generated 2026-06-17 — lds-hdl project*
