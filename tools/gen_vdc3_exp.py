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

factors = [3**i for i in range(19, -1, -1)]

for n in range(1, 13):
    work = n
    accum = 0
    idx = 0
    while work != 0 and idx <= 19:
        accum += mod3(work) * factors[idx]
        work = div3(work)
        idx += 1
    val = accum & 0xFFFFFFFF
    print(f"        expected[{n-1:2d}] = 32'h{val:08X};  // n={n}")
