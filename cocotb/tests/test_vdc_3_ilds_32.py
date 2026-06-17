import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, ClockCycles


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


def vdc3_ilds_expected(n):
    work = n
    accum = 0
    idx = 0
    while work != 0 and idx <= 19:
        accum += mod3(work) * FACTORS[idx]
        work = div3(work)
        idx += 1
    return accum & 0xFFFFFFFF


@cocotb.test()
async def test_vdc_3_ilds_32(dut):
    cocotb.start_soon(Clock(dut.clk, 10, unit="step").start())

    dut.rst_n.value = 0
    dut.en.value = 0
    await ClockCycles(dut.clk, 3)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)

    passed = 0
    failed = 0

    for n in range(1, 13):
        dut.en.value = 1
        await RisingEdge(dut.clk)
        dut.en.value = 0

        for _ in range(40):
            await RisingEdge(dut.clk)
            if dut.valid.value:
                expected = vdc3_ilds_expected(n)
                got = dut.vdc_out.value.integer
                if got == expected:
                    passed += 1
                else:
                    failed += 1
                    dut._log.error(
                        f"n={n}: expected 0x{expected:08X}, got 0x{got:08X}"
                    )
                break

    dut._log.info(f"Passed: {passed} / Failed: {failed}")
    assert failed == 0, f"{failed} tests failed"
