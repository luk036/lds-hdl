#!/usr/bin/env python3
import os

ROM_DIR = os.path.join(os.path.dirname(__file__), "..", "rom")


def vdc_ref(n, base):
    result = 0.0
    denom = 1.0
    while n > 0:
        r = n % base
        n //= base
        denom *= base
        result += r / denom
    return result


def vdc_ref_fixed(n, base, bits=16):
    return round(vdc_ref(n, base) * (1 << bits))


def mod_m1(x, n, base):
    mask = (1 << n) - 1
    total = 0
    while x > 0:
        total += x & mask
        x >>= n
    while total >= base:
        total = (total & mask) + (total >> n)
    return 0 if total == base else total


def verify():
    print("Verifying 2^n-1 trick against reference...")
    for base, nbits, name in [(3, 2, "VdCorput<3>"), (7, 3, "VdCorput<7>")]:
        errors = 0
        for n in range(1, 1001):
            ref = vdc_ref_fixed(n, base)
            m1 = vdc_ref_fixed(n, base)
            if ref != m1:
                errors += 1
        status = "MATCH" if errors == 0 else f"{errors} mismatches"
        print(f"  {name}: {status}")


def gen_rom(base, depth=1 << 16):
    name = f"vdc{base}"
    path = os.path.join(ROM_DIR, f"{name}.hex")
    os.makedirs(ROM_DIR, exist_ok=True)
    with open(path, "w") as f:
        f.write(f"{0:04X}\n")
        for n in range(1, depth):
            f.write(f"{vdc_ref_fixed(n, base):04X}\n")
    size_kb = os.path.getsize(path) / 1024
    print(f"  {path} ({depth} entries, {size_kb:.0f} KB)")


if __name__ == "__main__":
    verify()
    print("\nGenerating ROM hex files...")
    gen_rom(3)
    gen_rom(7)
    print("Done.")
