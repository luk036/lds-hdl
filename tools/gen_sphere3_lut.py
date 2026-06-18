#!/usr/bin/env python3
"""Generate LUT values for Sphere3([7,2,3]) Verilog module.

The LUT maps VdC<7> output to angle_xi (in cordic_32 input format).
VdC<7> output is VdC * 7^11, a 31-bit value in [0, 1977326742].

The mapping: VdC<7> → ti = pi/2 * VdC → xi = inv_F2(ti) → angle = xi / (2pi) * 2^32
"""

import math
import sys

N_LUT = 256           # number of LUT entries
PI = math.pi
HALF_PI = PI / 2.0
TWO_PI = 2.0 * PI

# Precomputed tables (same as C++ sphere_n.cpp)
N_TABLE = 300
X = [i * PI / (N_TABLE - 1) for i in range(N_TABLE)]  # linspace(0, PI, 300)
NEG_COSINE = [-math.cos(x) for x in X]
SINE = [math.sin(x) for x in X]
F2 = [(X[i] + NEG_COSINE[i] * SINE[i]) / 2.0 for i in range(N_TABLE)]

# VdC<7> scaling: output is VdC * 7^11, max = 7^11 - 1 = 1977326742
VDC7_MAX = 7**11 - 1  # = 1977326742

def simple_interp(x_value, x_points, y_points):
    """Linear interpolation (same as C++ sphere_n.cpp)."""
    if x_value <= x_points[0]:
        return y_points[0]
    if x_value >= x_points[-1]:
        return y_points[-1]
    # Binary search
    lo, hi = 0, len(x_points) - 1
    while hi - lo > 1:
        mid = (lo + hi) // 2
        if x_points[mid] <= x_value:
            lo = mid
        else:
            hi = mid
    t = (x_value - x_points[lo]) / (x_points[hi] - x_points[lo])
    return y_points[lo] + t * (y_points[hi] - y_points[lo])


def compute_lut():
    """Compute the LUT: maps VdC<7> value to angle_xi in cordic format."""
    angles = []
    for i in range(N_LUT + 1):  # N_LUT+1 entries for interpolation
        # VdC value at entry i (boundary)
        v = i / N_LUT  # VdC value in [0, 1]
        ti = HALF_PI * v  # ti in [0, pi/2]
        xi = simple_interp(ti, F2, X)  # xi in [0, pi]
        # Convert to cordic_32 angle format: 0 = 0°, 2^32 = 360°
        angle = int(round(xi / TWO_PI * (2**32))) & 0xFFFFFFFF
        angles.append(angle)
    return angles


def format_verilog_lut(angles):
    """Format LUT as Verilog initial block."""
    lines = []
    lines.append("    reg [31:0] angle_lut [0:%d];" % (len(angles) - 1))
    lines.append("    initial begin")
    for i, a in enumerate(angles):
        if i % 8 == 0:
            lines.append("        /* %3d-%3d */" % (i, min(i+7, len(angles)-1)))
        line_parts = []
        for j in range(8):
            idx = i + j
            if idx < len(angles):
                line_parts.append("angle_lut[%3d]=32'h%08X" % (idx, angles[idx]))
        if line_parts:
            lines.append("        " + "; ".join(line_parts) + ";")
    lines.append("    end")
    return "\n".join(lines)


def format_c_header(angles):
    """Format LUT as C header for verification."""
    lines = []
    lines.append("#ifndef SPHERE3_LUT_H")
    lines.append("#define SPHERE3_LUT_H")
    lines.append("")
    lines.append("#define SPHERE3_LUT_SIZE %d" % len(angles))
    lines.append("")
    lines.append("static const unsigned int sphere3_angle_lut[SPHERE3_LUT_SIZE] = {")
    for i in range(0, len(angles), 8):
        chunk = angles[i:i+8]
        hex_vals = ", ".join("0x%08X" % a for a in chunk)
        lines.append("    %s," % hex_vals)
    lines.append("};")
    lines.append("")
    lines.append("#endif")
    return "\n".join(lines)


def compute_expected(n_points=10):
    """Compute expected sphere3 values for verification."""
    def vdc7(n):
        """VdC<7> computation."""
        result = 0.0
        denom = 1.0
        cnt = n
        while cnt != 0:
            remainder = cnt % 7
            cnt //= 7
            denom *= 7.0
            result += remainder / denom
        return result

    def sphere23(n):
        """Sphere<2,3> computation (floating point reference)."""
        def vdc2(m):
            """VdC<2>."""
            rev = 0
            x = m
            for _ in range(32):
                rev = (rev << 1) | (x & 1)
                x >>= 1
            return rev / (2**32)

        def vdc3(m):
            """VdC<3>."""
            result = 0.0
            denom = 1.0
            cnt = m
            while cnt != 0:
                remainder = cnt % 3
                cnt //= 3
                denom *= 3.0
                result += remainder / denom
            return result

        # Sphere<2,3>: cosphi = 2*VdC<2> - 1, sinphi = sqrt(1 - cosphi^2)
        # Circle<3>: angle = 2*pi*VdC<3>, point = (cos, sin)
        cosphi = 2.0 * vdc2(n) - 1.0
        sinphi = math.sqrt(1.0 - cosphi * cosphi)
        theta = TWO_PI * vdc3(n)
        return (sinphi * math.cos(theta), sinphi * math.sin(theta), cosphi)

    print("\n# Expected Sphere3([7,2,3]) values (floating-point)")
    print("# idx  vdc7_val  xi(rad)  cosxi  sinxi  sp_x  sp_y  sp_z  out_x  out_y  out_z  out_w\n")

    for n in range(1, n_points + 1):
        vdc7_val = vdc7(n)
        ti = HALF_PI * vdc7_val
        xi = simple_interp(ti, F2, X)
        cosxi = math.cos(xi)
        sinxi = math.sin(xi)
        sp = sphere23(n)
        ox = sinxi * sp[0]
        oy = sinxi * sp[1]
        oz = sinxi * sp[2]
        ow = cosxi
        print("n=%2d: vdc7=%.10f xi=%.10f cosxi=%+.10f sinxi=%+.10f"
              % (n, vdc7_val, xi, cosxi, sinxi))
        print("      sp=(%+.10f, %+.10f, %+.10f) → out=(%+.10f, %+.10f, %+.10f, %+.10f)"
              % (sp[0], sp[1], sp[2], ox, oy, oz, ow))

    print("\n# Q1.31 fixed-point (32-bit signed)")
    print("# idx  x_hex       y_hex       z_hex       w_hex\n")

    for n in range(1, n_points + 1):
        vdc7_val = vdc7(n)
        ti = HALF_PI * vdc7_val
        xi = simple_interp(ti, F2, X)
        cosxi = math.cos(xi)
        sinxi = math.sin(xi)
        sp = sphere23(n)
        ox = sinxi * sp[0]
        oy = sinxi * sp[1]
        oz = sinxi * sp[2]
        ow = cosxi

        def to_q31(v):
            v = max(-1.0, min(1.0 - 1e-10, v))
            return int(round(v * (2**31))) & 0xFFFFFFFF

        print("n=%2d  0x%08X 0x%08X 0x%08X 0x%08X"
              % (n, to_q31(ox), to_q31(oy), to_q31(oz), to_q31(ow)))


if __name__ == "__main__":
    angles = compute_lut()

    if "--verilog" in sys.argv:
        print(format_verilog_lut(angles))
    elif "--c-header" in sys.argv:
        print(format_c_header(angles))
    elif "--expected" in sys.argv:
        compute_expected(10)
    else:
        print("Usage: gen_sphere3_lut.py [--verilog | --c-header | --expected]")
        print(f"\nGenerated {len(angles)} LUT entries")
        print(f"LUT range: 0x{angles[0]:08X} to 0x{angles[-1]:08X}")
