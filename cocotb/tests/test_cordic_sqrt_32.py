import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, ClockCycles
import math


def expected_sqrt(x_float):
    if x_float <= 0:
        return 0
    s = math.sqrt(x_float)
    return int(round(s * 2**32)) & 0xFFFFFFFF


@cocotb.test()
async def test_cordic_sqrt_32(dut):
    cocotb.start_soon(Clock(dut.clk, 10, unit="step").start())

    dut.rst_n.value = 0
    dut.en.value = 0
    dut.x_in.value = 0
    await ClockCycles(dut.clk, 3)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)

    passed = 0
    failed = 0
    threshold = 100

    # Values >= 0x01000000 (normalization handles these well)
    test_inputs = [
        0x01000000,
        0x04000000,
        0x10000000,
        0x20000000,
        0x40000000,
        0x80000000,
        0xC0000000,
        0xFFFFFFFF,
    ]

    for x_hex in test_inputs:
        x_float = x_hex / 2**32
        dut.x_in.value = x_hex
        dut.en.value = 1
        await RisingEdge(dut.clk)
        dut.en.value = 0

        for _ in range(30):
            await RisingEdge(dut.clk)
            if dut.valid.value:
                exp = expected_sqrt(x_float)
                got = dut.sqrt_out.value.integer
                err = abs(got - exp) if got > exp else abs(exp - got)

                if err < threshold:
                    passed += 1
                else:
                    failed += 1
                    dut._log.error(
                        f"sqrt(0x{x_hex:08X}): expected 0x{exp:08X}, "
                        f"got 0x{got:08X}, err={err}"
                    )
                break

    dut._log.info(f"Passed: {passed} / Failed: {failed}")
    assert failed == 0, f"{failed} tests failed"
