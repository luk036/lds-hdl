import math
N = 256
P = math.pi
H = P / 2.0
T = 2.0 * P
X = [i * P / 299 for i in range(300)]
neg_cos = [-math.cos(x) for x in X]
sin_x = [math.sin(x) for x in X]
F2 = [(X[i] + neg_cos[i] * sin_x[i]) / 2.0 for i in range(300)]

def interp(xv):
    if xv <= F2[0]:
        return X[0]
    if xv >= F2[-1]:
        return X[-1]
    lo, hi = 0, len(F2) - 1
    while hi - lo > 1:
        mid = (lo + hi) // 2
        if F2[mid] <= xv:
            lo = mid
        else:
            hi = mid
    t = (xv - F2[lo]) / (F2[hi] - F2[lo])
    return X[lo] + t * (X[hi] - X[lo])

angles = []
for i in range(N + 1):
    v = i / N
    xi = interp(H * v)
    a = int(round(xi / T * (2**32))) & 0xFFFFFFFF
    angles.append(a)

print('    reg [31:0] angle_lut [0:256];')
print('    initial begin')
for i in range(0, len(angles), 8):
    items = []
    n = min(8, len(angles) - i)
    for j in range(n):
        items.append('angle_lut[%3d]=32'"'"'h%08X' % (i + j, angles[i + j]))
    print('        ' + ('; '.join(items)) + ';')
print('    end')
