import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, ClockCycles


@cocotb.test()
async def test_sphere3_32(dut):
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

        for _ in range(200):
            await RisingEdge(dut.clk)
            if dut.valid.value:
                raw_x = dut.x.value.integer
                raw_y = dut.y.value.integer
                raw_z = dut.z.value.integer
                raw_w = dut.w.value.integer

                def from_s(v):
                    return v if v < 2**31 else v - 2**32

                x = from_s(raw_x)
                y = from_s(raw_y)
                z = from_s(raw_z)
                w = from_s(raw_w)

                mag_sq_x2 = (x * x) >> 30
                mag_sq_y2 = (y * y) >> 30
                mag_sq_z2 = (z * z) >> 30
                mag_sq_w2 = (w * w) >> 30
                mag_sq = mag_sq_x2 + mag_sq_y2 + mag_sq_z2 + mag_sq_w2

                # Check: x^2 + y^2 + z^2 + w^2 ≈ 1.0 (point on unit 3-sphere)
                if abs(mag_sq - 2**32) < 2**27:  # within ~3% tolerance
                    passed += 1
                else:
                    failed += 1
                    dut._log.error(
                        f"n={n}: x=0x{raw_x:08X} y=0x{raw_y:08X} "
                        f"z=0x{raw_z:08X} w=0x{raw_w:08X} "
                        f"mag_sq={mag_sq}"
                    )
                break

    dut._log.info(f"Passed: {passed} / Failed: {failed}")
    assert failed == 0, f"{failed} tests failed"
