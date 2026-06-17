`timescale 1 ns / 1 ps

module tb_sqrt_32;

    reg clk, rst_n, en;
    reg [31:0] x_in;
    wire [31:0] sqrt_out;
    wire valid;
    cordic_sqrt_32 dut(.*);

    localparam CLK_PERIOD = 100;
    initial clk = 0;
    always #(CLK_PERIOD/2) clk = ~clk;

    integer i, pc, fc, err;
    reg [31:0] got;
    reg [31:0] test_inputs [0:7];
    reg [31:0] expected [0:7];

    initial begin
        test_inputs[0] = 32'h01000000; expected[0] = 32'h10000000;
        test_inputs[1] = 32'h04000000; expected[1] = 32'h20000000;
        test_inputs[2] = 32'h10000000; expected[2] = 32'h40000000;
        test_inputs[3] = 32'h20000000; expected[3] = 32'h5A82799A;
        test_inputs[4] = 32'h40000000; expected[4] = 32'h80000000;
        test_inputs[5] = 32'h80000000; expected[5] = 32'hB504F334;
        test_inputs[6] = 32'hC0000000; expected[6] = 32'hDDB3D743;
        test_inputs[7] = 32'hFFFFFFFF; expected[7] = 32'hFFFFFFFF;
    end

    initial begin
        pc=0; fc=0; en=0; x_in=0;
        rst_n=0; #200 rst_n=1; #100;
        $display("CORDIC SQRT 32-bit test");
        $display("  idx   x_in           got            expected         err");
        for (i=0; i<8; i=i+1) begin
            x_in = test_inputs[i];
            @(posedge clk); #1;
            en=1; @(posedge clk); #1; en=0;
            @(posedge valid); #1;
            got = sqrt_out;
            if (got > expected[i]) err = got - expected[i];
            else err = expected[i] - got;
            $write("  %2d   0x%08X   0x%08X   0x%08X   %6d",
                   i+1, test_inputs[i], got, expected[i], err);
            if (err < 100) begin $display("  PASS"); pc=pc+1; end
            else begin $display("  FAIL"); fc=fc+1; end
        end
        $display("Passed: %0d / Failed: %0d", pc, fc);
        if (fc==0) $display("ALL PASS");
        #200; $finish;
    end
    initial #(CLK_PERIOD*500) $display("FATAL TIMEOUT");
endmodule
