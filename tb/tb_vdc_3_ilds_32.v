`timescale 1 ns / 1 ps

module tb_vdc_3_ilds_32;

    reg        clk;
    reg        rst_n;
    reg        en;
    wire [31:0] vdc_out;
    wire       valid;

    vdc_3_ilds_32 dut (.*);

    localparam integer NX = 12;
    reg [31:0] expected [0:NX-1];

    initial begin
        expected[ 0] = 32'h4546B3DB;  // n=1
        expected[ 1] = 32'h8A8D67B6;  // n=2
        expected[ 2] = 32'h17179149;  // n=3
        expected[ 3] = 32'h5C5E4524;  // n=4
        expected[ 4] = 32'hA1A4F8FF;  // n=5
        expected[ 5] = 32'h2E2F2292;  // n=6
        expected[ 6] = 32'h7375D66D;  // n=7
        expected[ 7] = 32'hB8BC8A48;  // n=8
        expected[ 8] = 32'h07B285C3;  // n=9
        expected[ 9] = 32'h4CF9399E;  // n=10
        expected[10] = 32'h923FED79;  // n=11
        expected[11] = 32'h1ECA170C;  // n=12
    end

    localparam CLK_PERIOD = 100;
    initial clk = 1'b0;
    always #(CLK_PERIOD / 2) clk = ~clk;

    integer pass_count;
    integer fail_count;
    integer i, j;
    reg found;

    initial begin
        pass_count = 0;
        fail_count = 0;
        en = 1'b0;

        rst_n = 1'b0;
        #(CLK_PERIOD * 2);
        rst_n = 1'b1;
        #(CLK_PERIOD * 1);

        $display("------------------------------------------------------------");
        $display("  VdCorput<3>  ILDS  32-bit");
        $display("------------------------------------------------------------");
        $display("  idx   expected        got            pass/fail");
        $display("------------------------------------------------------------");

        for (i = 0; i < NX; i = i + 1) begin
            en = 1'b1;
            @(posedge clk);
            #1;
            en = 1'b0;

            found = 1'b0;
            for (j = 0; j < 40; j = j + 1) begin
                @(posedge clk);
                #1;
                if (valid) begin
                    $write("  %2d | 0x%08X  | 0x%08X  ", i+1, expected[i], vdc_out);
                    if (vdc_out === expected[i]) begin
                        $display("  PASS (cycle %0d)", j+1);
                        pass_count = pass_count + 1;
                    end else begin
                        $display("  FAIL  (expected 0x%08X)", expected[i]);
                        fail_count = fail_count + 1;
                    end
                    found = 1'b1;
                    j = 40;
                end
            end
            if (!found) begin
                $display("  %2d | 0x%08X  |  TIMEOUT    FAIL", i+1, expected[i]);
                fail_count = fail_count + 1;
            end
        end

        $display("------------------------------------------------------------");
        $display("  Passed: %0d  /  Failed: %0d", pass_count, fail_count);
        if (fail_count == 0) $display("  *** ALL TESTS PASSED ***");
        else                 $display("  *** SOME TESTS FAILED ***");
        $display("------------------------------------------------------------");
        #(CLK_PERIOD * 2);
        $finish;
    end

    initial #(CLK_PERIOD * 500) begin
        $display("FATAL TIMEOUT");
        $finish;
    end

    initial begin
        $dumpfile("tb_vdc_3_ilds_32.vcd");
        $dumpvars(0, tb_vdc_3_ilds_32);
    end

endmodule
