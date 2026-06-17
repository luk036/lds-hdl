import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, ClockCycles
import math


def mod3(x):
    s = 0
    for i in range(0, 32, 2):
        s += (x >> i) & 3
    s = (s & 3) + ((s >> 2) & 3)
    s = (s & 3) + ((s >> 2) & 3)
    if s >= 3:
        s -= 3
    return s


def div3(x):
    return (x * 0x0000000155555556) >> 34


FACTORS = [3**i for i in range(19, -1, -1)]


def vdc3_ilds_value(n):
    work = n
    accum = 0
    idx = 0
    while work != 0 and idx <= 19:
        accum += mod3(work) * FACTORS[idx]
        work = div3(work)
        idx += 1
    return accum & 0xFFFFFFFF


SCALE32 = round(72736 / 65536 * 2**32)


def expected_cos_sin_from_vdc3(n):
    raw = vdc3_ilds_value(n)
    angle32 = (raw * SCALE32) >> 32
    angle_rad = angle32 / 2**32 * 2 * math.pi
    c = int(round(math.cos(angle_rad) * 2**31))
    s = int(round(math.sin(angle_rad) * 2**31))
    if c >= 2**31: c = 2**31 - 1
    if c < -2**31: c = -2**31
    if s >= 2**31: s = 2**31 - 1
    if s < -2**31: s = -2**31
    return c & 0xFFFFFFFF, s & 0xFFFFFFFF


@cocotb.test()
async def test_circle_3_32(dut):
    cocotb.start_soon(Clock(dut.clk, 10, unit="step").start())

    dut.rst_n.value = 0
    dut.en.value = 0
    await ClockCycles(dut.clk, 3)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)

    passed = 0
    failed = 0
    threshold = 2000

    for n in range(1, 13):
        exp_cos, exp_sin = expected_cos_sin_from_vdc3(n)

        dut.en.value = 1
        await RisingEdge(dut.clk)
        dut.en.value = 0

        for _ in range(60):
            await RisingEdge(dut.clk)
            if dut.valid.value:
                got_cos = dut.cos.value.signed_integer
                got_sin = dut.sin.value.signed_integer

                err_c = abs(got_cos - (exp_cos if exp_cos < 2**31 else exp_cos - 2**32))
                err_s = abs(got_sin - (exp_sin if exp_sin < 2**31 else exp_sin - 2**32))

                if err_c < threshold and err_s < threshold:
                    passed += 1
                else:
                    failed += 1
                    dut._log.error(
                        f"n={n}: cos err={err_c}, sin err={err_s}"
                    )
                break

    dut._log.info(f"Passed: {passed} / Failed: {failed}")
    assert failed == 0, f"{failed} tests failed"
