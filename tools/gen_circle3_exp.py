import math

scale32 = round(72736 / 65536 * 2**32)

def mod3(x):
    s = 0
    for i in range(0, 32, 2):
        s += (x >> i) & 3
    s = (s & 3) + ((s >> 2) & 3)
    s = (s & 3) + ((s >> 2) & 3)
    if s >= 3: s -= 3
    return s

def div3(x):
    return (x * 0x0000000155555556) >> 34

def vdc3_ilds_32(n):
    factors = [3**i for i in range(19, -1, -1)]
    work = n
    accum = 0
    idx = 0
    while work != 0 and idx <= 19:
        accum += mod3(work) * factors[idx]
        work = div3(work)
        idx += 1
    return accum & 0xFFFFFFFF

for n in range(1, 13):
    raw = vdc3_ilds_32(n)
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
    print(f"        ec[{n-1:2d}]=32'h{c_u:08X}; es[{n-1:2d}]=32'h{s_u:08X};  // n={n}")
