`timescale 1 ns / 1 ps
module tb_sqrt_16;
    reg clk, rst_n, en;
    wire [15:0] out;
    wire valid;
    cordic_sqrt_16 dut(.*);
    localparam CP = 100;
    initial clk = 0;
    always #(CP/2) clk = ~clk;
    integer i, pc, fc;
    reg [15:0] got;
    initial begin
        pc=0; fc=0; en=0;
        rst_n=0; #200 rst_n=1; #100;
        $display("sqrt test");
        $display("  idx   in     expected got    err");
        for (i=0; i<16; i=i+1) begin
            en=1; @(posedge clk); #1; en=0;
            @(posedge valid); #1;
            got = out;
            $write("  %2d  0x%04X  0x%04X  0x%04X", i+1, dut.x_in, got, got);
            $display("  ?");
        end
        #200; $finish;
    end
    initial #(CP*500) $display("FATAL TIMEOUT");
endmodule
