#!/usr/bin/env python3
"""Compute all 32-bit numeric constants for lds-hdl 32-bit migration."""

import math

print('=== CORDIC 32-bit Constants ===')
print()

# Full circle = 2^32
FULL = 2**32
TAU = 2 * math.pi

# atan table for 32-bit: 31 entries
print('// atan table (32-bit, full circle = 2^32)')
for i in range(31):
    val = round(math.atan(2**(-i)) * FULL / TAU)
    print(f'            atan[{i:2d}] = 32&#39;d{val:10d};  // 0x{val:08X}')
print()

# XI = 1/K * 2^33 (for Q2.32 internal, 34-bit signed)
K = 1.646760258121065
invK = 1.0 / K
XI = round(invK * 2**33)
print(f'// XI = 1/K_cordic * 2^33 (Q2.32)')
print(f'// K = {K:.9f}, 1/K = {invK:.9f}')
print(f'// XI = 34&#39;d{XI}  (0x{XI:09X})')
print()

print('=== CORDIC SQRT 32-bit Constants ===')
print()

# INV_KH: 1/K_h * 2^32, where K_h is hyperbolic gain after 20 iterations
# Shift sequence: 1,2,3,4,4,5,6,7,8,9,10,11,12,13,13,14,15,16,17,18
shifts = [1,2,3,4,4,5,6,7,8,9,10,11,12,13,13,14,15,16,17,18]
Kh = 1.0
for s in shifts:
    Kh *= math.sqrt(1 - 2**(-2*s))
invKh = 1.0 / Kh
print(f'// K_h (hyperbolic gain after 20 iterations) = {Kh:.9f}')
print(f'// 1/K_h = {invKh:.9f}')
INV_KH = round(invKh * 2**32)
print(f'// INV_KH = round(1/K_h * 2^32) = 32&#39;d{INV_KH}  (0x{INV_KH:08X})')
print()

# Normalization thresholds for 32-bit
# 16-bit thresholds: 0x0100, 0x0400, 0x1000 (scaled by 2^16 each)
print(f'// 32-bit norm thresholds:')
print(f'//   w < 32&#39;h01000000 → shift 6 (norm_val = w << 6, norm_shift = 3)')
print(f'//   w < 32&#39;h04000000 → shift 4 (norm_val = w << 4, norm_shift = 2)')
print(f'//   w < 32&#39;h10000000 → shift 2 (norm_val = w << 2, norm_shift = 1)')
print(f'//   else → shift 0 (norm_val = w, norm_shift = 0)')
print(f'// Each norm_shift unit represents >> 1 on the result (i.e. div by 2 per unit)')
print()

# 0.25 in Q2.32
qtr = int(0.25 * 2**32)
print(f'// 0.25 in Q2.32 = {qtr} = 34&#39;h{qtr:09X}')
print()

print('=== VDC_3_ILDS_32 Constants ===')
print()

# Need log_3(2^32) ≈ 20.2 → 21 iterations (indices 0-20)
N_ITER = 21
print(f'// {N_ITER} iterations (base-3 digits for 32-bit precision)')
print(f'// 3^{N_ITER} = {3**N_ITER}')
print()

# Factor table: 3^i for i = N_ITER-1 down to 0
print('// factor table (powers of 3, 32-bit)')
for i in range(N_ITER):
    exp = N_ITER - 1 - i
    val = 3**exp
    print(f'        assign factor[{i:2d}] = 32&#39;d{val:10d};  // 3^{exp}')
print()

# div3 constant for 32-bit
# 16-bit uses: div3 = (x * 32'h0000AAAB) >> 17  (AAAB = 2^18/3 + 1)
# For 32-bit: need (x * N) >> M where N * M matches 64-bit intermediate
# x is 32-bit, we want result ≡ floor(x/3)
# Use: (x * 64'hAAAA_AAAA_AAAA_AAAB) >> 65 is common
# But simpler: (x * 34-bit constant) >> 34
# 2^34 / 3 ≈ 5726623061.33 → 5726623061 floor, + 1 = 5726623062
div3_const = (2**34) // 3 + 1
print(f'// div3: for 32-bit x, result = (x * 64&#39;h{div3_const:016X}) >> 34')
print()

# mod3 function structure for 32-bit
print('// mod3 function: sum of 16 2-bit chunks from 32-bit input, reduce to < 3')
print()

print('=== CIRCLE_3_32 Constants ===')
print()
print(f'// VdC<3> output is UQ0.32, directly maps to angle (both use 2^32 full range)')
print(f'// No scaling needed: angle = vdc_out')
print(f'// (16-bit version needed scaling because VdC<3> output range != CORDIC input range)')
print(f'// Wait: 16-bit circle_3 uses: angle = (raw * 32&#39;d72736) >> 16')
print(f'// 72736 / 65536 ≈ 1.1099  → this accounts for VdC<3> not covering [0,1) fully?')
print(f'// Actually VdC<3> DOES cover [0,1). The scaling factor 72736/65536 adds a small angle offset.')
print(f'// For 32-bit: same scaling = round(72736/65536 * 2^32) = round(1.1099 * 2^32)')
scale_32 = round(72736 / 65536 * 2**32)
print(f'// angle = (raw * 64&#39;d{scale_32}) >> 32')
print()

print('=== SPHERE_32 Constants ===')
print()
half_f = 2**31
print(f'// cosphi = raw_phi - {half_f} = raw_phi - 32&#39;h{half_f:08X}')
print(f'// |cosphi| uses 31-bit magnitude')
print(f'// |cosphi|^2 uses 62-bit product')
print(f'// 1.0 in Q2.62 = 2^62 = 64&#39;h{2**62:016X}')
print(f'// remainder = 1.0 - cosphi^2')
print(f'// sqrt_in = (remainder >> 30) in UQ0.32')
print(f'// Saturation: if remainder > 2^62-1, cap at 0xFFFFFFFF')
print()

print('=== DISK_32 Constants ===')
print()
print(f'// raw_scaled = (raw * 64&#39;d{scale_32}) >> 32  (same scaling as circle_3)')
print(f'// product: radius(U0.32) * cos/sin(Q1.31) → 64-bit, >> 32 for Q1.31 output')
print()
