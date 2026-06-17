`timescale 1 ns / 1 ps

module tb_vdc_32;

    reg        clk;
    reg        rst_n;
    reg        en;
    wire [31:0] vdc_out;
    wire       valid;

    vdc_32 dut (
        .clk    (clk),
        .rst_n  (rst_n),
        .en     (en),
        .vdc_out(vdc_out),
        .valid  (valid)
    );

    localparam integer N_EXPECTED = 20;
    reg [31:0] expected [0:N_EXPECTED-1];

    initial begin
        expected[ 0] = 32'h80000000;   // n=1
        expected[ 1] = 32'h40000000;   // n=2
        expected[ 2] = 32'hC0000000;   // n=3
        expected[ 3] = 32'h20000000;   // n=4
        expected[ 4] = 32'hA0000000;   // n=5
        expected[ 5] = 32'h60000000;   // n=6
        expected[ 6] = 32'hE0000000;   // n=7
        expected[ 7] = 32'h10000000;   // n=8
        expected[ 8] = 32'h90000000;   // n=9
        expected[ 9] = 32'h50000000;   // n=10
        expected[10] = 32'hD0000000;   // n=11
        expected[11] = 32'h30000000;   // n=12
        expected[12] = 32'hB0000000;   // n=13
        expected[13] = 32'h70000000;   // n=14
        expected[14] = 32'hF0000000;   // n=15
        expected[15] = 32'h08000000;   // n=16
        expected[16] = 32'h88000000;   // n=17
        expected[17] = 32'h48000000;   // n=18
        expected[18] = 32'hC8000000;   // n=19
        expected[19] = 32'h28000000;   // n=20
    end

    localparam CLK_PERIOD = 100;
    initial clk = 1'b0;
    always #(CLK_PERIOD / 2) clk = ~clk;

    integer pass_count;
    integer fail_count;
    integer i;

    initial begin
        pass_count = 0;
        fail_count = 0;
        en = 1'b0;

        rst_n = 1'b0;
        #(CLK_PERIOD * 2);
        rst_n = 1'b1;
        #(CLK_PERIOD * 1);

        $display("------------------------------------------------------------");
        $display("  VdCorput<2>  32-bit  Verification");
        $display("------------------------------------------------------------");
        $display("  idx   expected        got            VdC(float)  pass/fail");
        $display("------------------------------------------------------------");

        en = 1'b1;
        for (i = 0; i < N_EXPECTED; i = i + 1) begin
            @(posedge clk);
            #1;

            if (valid) begin
                $write("  %2d | 0x%08X  | 0x%08X | %f  ",
                       i + 1, expected[i], vdc_out,
                       $itor(vdc_out) / 4294967296.0);

                if (vdc_out === expected[i]) begin
                    $display("PASS");
                    pass_count = pass_count + 1;
                end else begin
                    $display("FAIL  (expected 0x%08X)", expected[i]);
                    fail_count = fail_count + 1;
                end
            end
        end

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

    initial begin
        #(CLK_PERIOD * 100);
        $display("TIMEOUT: Test did not complete in time.");
        $finish;
    end

    initial begin
        $dumpfile("tb_vdc_32.vcd");
        $dumpvars(0, tb_vdc_32);
    end

endmodule
