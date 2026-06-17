#!/usr/bin/env python3
"""Compute expected test values for 32-bit testbenches."""
import math

# === vdc_32 expected values (n=1..20) ===
print('=== VDC_32 Expected ===')
for n in range(1, 21):
    rev = 0
    x = n
    for i in range(32):
        rev = (rev << 1) | (x & 1)
        x >>= 1
    print(f'        expected[{n-1:2d}] = 32\'h{rev:08X};  // n={n}')
print()

# === vdc_3_ilds_32 expected (n=1..12) ===
print('=== VDC_3_ILDS_32 Expected ===')
def vdc3_32(n):
    result = 0
    denom = 1.0
    cnt = n
    while cnt != 0:
        rem = cnt % 3
        cnt //= 3
        denom *= 3.0
        result += rem / denom
    return int(round(result * 2**32))

for n in range(1, 13):
    val = vdc3_32(n)
    print(f'        expected[{n-1:2d}] = 32\'h{val:08X};  // n={n}')
print()

# === circle_2 expected values (cos, sin for n=1..12) ===
print('=== CIRCLE_2_32 Expected (cos, sin) ===')
def vdc2_32(n):
    rev = 0
    x = n
    for i in range(32):
        rev = (rev << 1) | (x & 1)
        x >>= 1
    return rev

for n in range(1, 13):
    angle_raw = vdc2_32(n)
    angle_rad = angle_raw * 2 * math.pi / 2**32
    c = int(round(math.cos(angle_rad) * 2**31))
    s = int(round(math.sin(angle_rad) * 2**31))
    if c >= 2**31: c = 2**31 - 1
    if c < -2**31: c = -2**31
    if s >= 2**31: s = 2**31 - 1
    if s < -2**31: s = -2**31
    c_u = c & 0xFFFFFFFF
    s_u = s & 0xFFFFFFFF
    print(f'        ec[{n-1:2d}]=32\'h{c_u:08X}; es[{n-1:2d}]=32\'h{s_u:08X};  // n={n}  angle=0x{angle_raw:08X}')
print()

# === cordic_sqrt expected values ===
print('=== CORDIC_SQRT_32 Expected ===')
test_inputs = [0x10000000, 0x20000000, 0x40000000, 0x80000000, 0xC0000000, 0xFFFFFFFF]
for x_in in test_inputs:
    val = x_in / 2**32
    sqrt_val = math.sqrt(val)
    expected = int(round(sqrt_val * 2**32))
    print(f'        // sqrt(0x{x_in:08X}) = sqrt({val:.6f}) = {sqrt_val:.6f} -> 0x{expected:08X}')
print()

# === circle_3 expected values ===
print('=== CIRCLE_3_32 Expected (cos, sin) ===')
scale32 = round(72736 / 65536 * 2**32)
for n in range(1, 13):
    raw = vdc3_32(n)
    angle32 = (raw * scale32) >> 32
    angle_rad = angle32 * 2 * math.pi / 2**32
    c = int(round(math.cos(angle_rad) * 2**31))
    s = int(round(math.sin(angle_rad) * 2**31))
    if c >= 2**31: c = 2**31 - 1
    if c < -2**31: c = -2**31
    if s >= 2**31: s = 2**31 - 1
    if s < -2**31: s = -2**31
    c_u = c & 0xFFFFFFFF
    s_u = s & 0xFFFFFFFF
    print(f'        ec[{n-1:2d}]=32\'h{c_u:08X}; es[{n-1:2d}]=32\'h{s_u:08X};  // n={n}  raw=0x{raw:08X}  angle=0x{angle32:08X}')
