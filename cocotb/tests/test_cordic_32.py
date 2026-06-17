import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, ClockCycles
import math


def angle_to_cordic_input(angle_rad):
    return int(round(angle_rad / (2 * math.pi) * 2**32)) & 0xFFFFFFFF


def expected_cos_sin(angle_rad):
    c = int(round(math.cos(angle_rad) * 2**31))
    s = int(round(math.sin(angle_rad) * 2**31))
    if c >= 2**31: c = 2**31 - 1
    if c < -2**31: c = -2**31
    if s >= 2**31: s = 2**31 - 1
    if s < -2**31: s = -2**31
    return c & 0xFFFFFFFF, s & 0xFFFFFFFF


@cocotb.test()
async def test_cordic_32(dut):
    cocotb.start_soon(Clock(dut.clk, 10, unit="step").start())

    dut.rst_n.value = 0
    dut.en.value = 0
    dut.angle.value = 0
    await ClockCycles(dut.clk, 3)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)

    passed = 0
    failed = 0
    threshold = 50000

    test_angles = [
        0.0,               # 0 degrees
        math.pi / 2,       # 90
        math.pi,           # 180
        math.pi / 4,       # 45
        math.pi / 8,       # 22.5
        3 * math.pi / 4,   # 135
        5 * math.pi / 4,   # 225
        7 * math.pi / 4,   # 315
        math.pi / 16,      # 11.25
    ]

    for angle_rad in test_angles:
        dut.angle.value = angle_to_cordic_input(angle_rad)
        dut.en.value = 1
        await RisingEdge(dut.clk)
        dut.en.value = 0

        for _ in range(40):
            await RisingEdge(dut.clk)
            if dut.valid.value:
                exp_cos, exp_sin = expected_cos_sin(angle_rad)
                got_cos = dut.cos.value.signed_integer
                got_sin = dut.sin.value.signed_integer

                err_c = abs(got_cos - (exp_cos if exp_cos < 2**31 else exp_cos - 2**32))
                err_s = abs(got_sin - (exp_sin if exp_sin < 2**31 else exp_sin - 2**32))

                if err_c < threshold and err_s < threshold:
                    passed += 1
                else:
                    failed += 1
                    dut._log.error(
                        f"angle={angle_rad:.4f}: "
                        f"cos err={err_c}, sin err={err_s}"
                    )
                break

    dut._log.info(f"Passed: {passed} / Failed: {failed}")
    assert failed == 0, f"{failed} tests failed"
