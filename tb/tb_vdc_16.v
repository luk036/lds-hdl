// -----------------------------------------------------------------------------
// tb_vdc_16.v — Testbench for vdc_16 (base-2, 16-bit)
// -----------------------------------------------------------------------------
// Generates the first 20 values of the van der Corput sequence, prints them
// and compares against known-good expected values computed via the C++
// reference implementation (lds::vdc<2>(n) × 2^16).
//
// Expected values (index n starting from 1):
//
//   n  | VdC (float) |  expected [15:0]  | Notes
//  ----+-------------+-------------------+-------------------------------
//   1  |  0.5        |  0x8000           | 2^-1
//   2  |  0.25       |  0x4000           | 2^-2
//   3  |  0.75       |  0xC000           | 2^-1 + 2^-2
//   4  |  0.125      |  0x2000           | 2^-3
//   5  |  0.625      |  0xA000           | 2^-1 + 2^-3
//   6  |  0.375      |  0x6000           | 2^-2 + 2^-3
//   7  |  0.875      |  0xE000           | 2^-1 + 2^-2 + 2^-3
//   8  |  0.0625     |  0x1000           | 2^-4
//   9  |  0.5625     |  0x9000           | 2^-1 + 2^-4
//  10  |  0.3125     |  0x5000           | 2^-2 + 2^-4
//  11  |  0.8125     |  0xD000           | 2^-1 + 2^-2 + 2^-4
//  12  |  0.1875     |  0x3000           | 2^-3 + 2^-4
//  13  |  0.6875     |  0xB000           | 2^-1 + 2^-3 + 2^-4
//  14  |  0.4375     |  0x7000           | 2^-2 + 2^-3 + 2^-4
//  15  |  0.9375     |  0xF000           | 2^-1 + 2^-2 + 2^-3 + 2^-4
//  16  |  0.03125    |  0x0800           | 2^-5
//  17  |  0.53125    |  0x8800           | 2^-1 + 2^-5
//  18  |  0.28125    |  0x4800           | 2^-2 + 2^-5
//  19  |  0.78125    |  0xC800           | 2^-1 + 2^-2 + 2^-5
//  20  |  0.15625    |  0x2800           | 2^-3 + 2^-5
// -----------------------------------------------------------------------------

`timescale 1 ns / 1 ps

module tb_vdc_16;

    // ------------------------------------------------------------------
    // DUT signals
    // ------------------------------------------------------------------
    reg        clk;
    reg        rst_n;
    reg        en;
    wire [15:0] vdc_out;
    wire       valid;

    // ------------------------------------------------------------------
    // DUT instantiation
    // ------------------------------------------------------------------
    vdc_16 dut (
        .clk    (clk),
        .rst_n  (rst_n),
        .en     (en),
        .vdc_out(vdc_out),
        .valid  (valid)
    );

    // ------------------------------------------------------------------
    // Expected values (first 20)
    // ------------------------------------------------------------------
    localparam integer N_EXPECTED = 20;
    reg [15:0] expected [0:N_EXPECTED-1];

    initial begin
        expected[ 0] = 16'h8000;   // n=1
        expected[ 1] = 16'h4000;   // n=2
        expected[ 2] = 16'hC000;   // n=3
        expected[ 3] = 16'h2000;   // n=4
        expected[ 4] = 16'hA000;   // n=5
        expected[ 5] = 16'h6000;   // n=6
        expected[ 6] = 16'hE000;   // n=7
        expected[ 7] = 16'h1000;   // n=8
        expected[ 8] = 16'h9000;   // n=9
        expected[ 9] = 16'h5000;   // n=10
        expected[10] = 16'hD000;   // n=11
        expected[11] = 16'h3000;   // n=12
        expected[12] = 16'hB000;   // n=13
        expected[13] = 16'h7000;   // n=14
        expected[14] = 16'hF000;   // n=15
        expected[15] = 16'h0800;   // n=16
        expected[16] = 16'h8800;   // n=17
        expected[17] = 16'h4800;   // n=18
        expected[18] = 16'hC800;   // n=19
        expected[19] = 16'h2800;   // n=20
    end

    // ------------------------------------------------------------------
    // Clock generation (10 MHz → 100 ns period)
    // ------------------------------------------------------------------
    localparam CLK_PERIOD = 100;  // ns
    initial clk = 1'b0;
    always #(CLK_PERIOD / 2) clk = ~clk;

    // ------------------------------------------------------------------
    // Test stimulus
    // ------------------------------------------------------------------
    integer pass_count;
    integer fail_count;
    integer i;

    initial begin
        // --------------------------------------------------------------
        // Initialisation
        // --------------------------------------------------------------
        pass_count = 0;
        fail_count = 0;
        en         = 1'b0;

        // Reset
        rst_n = 1'b0;
        #(CLK_PERIOD * 2);
        rst_n = 1'b1;
        #(CLK_PERIOD * 1);

        // --------------------------------------------------------------
        // Header
        // --------------------------------------------------------------
        $display("------------------------------------------------------------");
        $display("  VdCorput<2>  16-bit  Verification");
        $display("------------------------------------------------------------");
        $display("  idx   expected    got       VdC(float)  pass/fail");
        $display("------------------------------------------------------------");

        // --------------------------------------------------------------
        // Generate first 20 sequence values
        // --------------------------------------------------------------
        en = 1'b1;
        for (i = 0; i < N_EXPECTED; i = i + 1) begin
            @(posedge clk);
            #1;  // small delta for signal settling

            if (valid) begin
                // Convert to floating-point approximation for display
                $write("  %2d | 0x%04X  | 0x%04X | %f  ",
                       i + 1, expected[i], vdc_out,
                       $itor(vdc_out) / 65536.0);

                if (vdc_out === expected[i]) begin
                    $display("PASS");
                    pass_count = pass_count + 1;
                end else begin
                    $display("FAIL  (expected 0x%04X)", expected[i]);
                    fail_count = fail_count + 1;
                end
            end
        end

        // --------------------------------------------------------------
        // Summary
        // --------------------------------------------------------------
        $display("------------------------------------------------------------");
        $display("  Passed: %0d  /  Failed: %0d", pass_count, fail_count);
        $display("------------------------------------------------------------");

        if (fail_count == 0) begin
            $display("  *** ALL TESTS PASSED ***");
        end else begin
            $display("  *** SOME TESTS FAILED ***");
        end
        $display("------------------------------------------------------------");

        #(CLK_PERIOD * 2);
        $finish;
    end

    // ------------------------------------------------------------------
    // Timeout watchdog (safety net)
    // ------------------------------------------------------------------
    initial begin
        #(CLK_PERIOD * 100);
        $display("TIMEOUT: Test did not complete in time.");
        $finish;
    end

    // ------------------------------------------------------------------
    // VCD dump for waveform viewing
    // ------------------------------------------------------------------
    initial begin
        $dumpfile("tb_vdc_16.vcd");
        $dumpvars(0, tb_vdc_16);
    end

endmodule
