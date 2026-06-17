import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, ClockCycles


@cocotb.test()
async def test_sphere_32(dut):
    cocotb.start_soon(Clock(dut.clk, 10, unit="step").start())

    dut.rst_n.value = 0
    dut.en.value = 0
    await ClockCycles(dut.clk, 3)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)

    passed = 0
    failed = 0

    for n in range(1, 11):
        dut.en.value = 1
        await RisingEdge(dut.clk)
        dut.en.value = 0

        for _ in range(150):
            await RisingEdge(dut.clk)
            if dut.valid.value:
                x = dut.x.value.signed_integer
                y = dut.y.value.signed_integer
                z = dut.z.value.signed_integer
                # Check: x^2 + y^2 + z^2 ≈ 1.0 (point on unit sphere)
                mag_sq = (x * x + y * y + z * z) >> 30
                if abs(mag_sq - 2**30) < 2**28:  # within ~25% tolerance
                    passed += 1
                else:
                    failed += 1
                    dut._log.error(
                        f"n={n}: x=0x{x:08X}, y=0x{y:08X}, z=0x{z:08X}, "
                        f"mag_sq={mag_sq}"
                    )
                break

    dut._log.info(f"Passed: {passed} / Failed: {failed}")
    assert failed == 0, f"{failed} tests failed"
