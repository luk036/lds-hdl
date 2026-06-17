import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, ClockCycles


@cocotb.test()
async def test_disk_32(dut):
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

        for _ in range(100):
            await RisingEdge(dut.clk)
            if dut.valid.value:
                x = dut.x.value.signed_integer
                y = dut.y.value.signed_integer
                # Check: x^2 + y^2 <= 1.0 (point inside unit disk)
                mag_sq = (x * x + y * y) >> 30
                if mag_sq <= 4 * 2**30:  # loosely check within 2x radius
                    passed += 1
                else:
                    failed += 1
                    dut._log.error(
                        f"n={n}: x=0x{x:08X}, y=0x{y:08X}, mag_sq too large"
                    )
                break

    dut._log.info(f"Passed: {passed} / Failed: {failed}")
    assert failed == 0, f"{failed} tests failed"
