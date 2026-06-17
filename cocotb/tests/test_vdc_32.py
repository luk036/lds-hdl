import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, ClockCycles


def bit_reverse_32(n):
    rev = 0
    x = n
    for _ in range(32):
        rev = (rev << 1) | (x & 1)
        x >>= 1
    return rev


@cocotb.test()
async def test_vdc_32(dut):
    cocotb.start_soon(Clock(dut.clk, 10, unit="step").start())

    dut.rst_n.value = 0
    dut.en.value = 0
    await ClockCycles(dut.clk, 5)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 2)

    passed = 0
    failed = 0

    for n in range(1, 21):
        dut.en.value = 1
        await RisingEdge(dut.clk)
        dut.en.value = 0
        while not dut.valid.value:
            await RisingEdge(dut.clk)
        expected = bit_reverse_32(n)
        got = dut.vdc_out.value.integer
        if got == expected:
            passed += 1
        else:
            failed += 1
            dut._log.error(f"n={n}: expected 0x{expected:08X}, got 0x{got:08X}")

    dut._log.info(f"Passed: {passed} / Failed: {failed}")
    assert failed == 0, f"{failed} tests failed"
