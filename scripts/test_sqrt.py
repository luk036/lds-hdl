import math

iters = []
i = 1
while len(iters) < 32:
    iters.append(i)
    if i in [4, 13]:
        iters.append(i)
    i += 1

def cordic_sqrt_norm(w, n=20):
    if w <= 0: return 0.0
    shift = 0
    while w < 0.25 and shift < 8:
        w *= 4.0
        shift += 1
    x, y = w + 0.25, w - 0.25
    kh = 1.0
    for idx in range(min(n, len(iters))):
        ii = iters[idx]
        kh *= math.sqrt(1 - 2**(-2*ii))
        d = -1 if y >= 0 else 1
        xn = x + d * y * 2**(-ii)
        yn = y + d * x * 2**(-ii)
        x, y = xn, yn
    result = x / kh
    while shift > 0:
        result /= 2.0
        shift -= 1
    return result

max_err = 0
worst_v = 0
for v in range(0, 65536):
    w = v / 65536.0
    true = math.sqrt(w)
    cord = cordic_sqrt_norm(w, 20)
    err = abs(cord - true) * 65536
    if err > max_err:
        max_err = err
        worst_v = v

print(f"Max error: {max_err:.2f} LSBs (at v={worst_v})")
print()

for v in [0, 100, 1000, 5000, 10000, 16384, 32768, 50000, 65535]:
    w = v / 65536.0
    true = math.sqrt(w)
    cord = cordic_sqrt_norm(w, 20)
    err = abs(cord - true) * 65536
    print(f"  v={v:5d}  w={w:.4f}  true={true:.6f}  cord={cord:.6f}  err={err:.2f} LSB")
