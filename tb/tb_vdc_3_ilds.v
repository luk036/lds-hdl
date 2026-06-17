`timescale 1 ns / 1 ps

module tb_vdc_3_ilds;

    reg        clk;
    reg        rst_n;
    reg        en;
    wire [15:0] vdc_out;
    wire       valid;

    vdc_3_ilds dut (.*);

    localparam integer NX = 12;
    reg [15:0] expected [0:NX-1];

    initial begin
        expected[ 0] = 16'h4CE3; expected[ 1] = 16'h99C6;
        expected[ 2] = 16'h19A1; expected[ 3] = 16'h6684;
        expected[ 4] = 16'hB367; expected[ 5] = 16'h3342;
        expected[ 6] = 16'h8025; expected[ 7] = 16'hCD08;
        expected[ 8] = 16'h088B; expected[ 9] = 16'h556E;
        expected[10] = 16'hA251; expected[11] = 16'h222C;
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
        $display("  VdCorput<3>  ILDS  (2^2-1 trick + exact int factors)");
        $display("------------------------------------------------------------");
        $display("  idx   expected    got       pass/fail");
        $display("------------------------------------------------------------");

        for (i = 0; i < NX; i = i + 1) begin
            en = 1'b1;
            @(posedge clk);
            #1;
            en = 1'b0;

            found = 1'b0;
            for (j = 0; j < 15; j = j + 1) begin
                @(posedge clk);
                #1;
                if (valid) begin
                    $write("  %2d | 0x%04X  | 0x%04X  ", i+1, expected[i], vdc_out);
                    if (vdc_out === expected[i]) begin
                        $display("  PASS (cycle %0d)", j+1);
                        pass_count = pass_count + 1;
                    end else begin
                        $display("  FAIL  (expected 0x%04X)", expected[i]);
                        fail_count = fail_count + 1;
                    end
                    found = 1'b1;
                    j = 15;
                end
            end
            if (!found) begin
                $display("  %2d | 0x%04X  |  TIMEOUT    FAIL", i+1, expected[i]);
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

    initial #(CLK_PERIOD * 300) begin
        $display("FATAL TIMEOUT");
        $finish;
    end

    initial begin
        $dumpfile("tb_vdc_3_ilds.vcd");
        $dumpvars(0, tb_vdc_3_ilds);
    end

endmodule
