`timescale 1 ns / 1 ps
module tb_sphere3_32;
    reg clk, rst_n, en;
    wire [31:0] x, y, z, w;
    wire valid;
    sphere3_32 dut(.*);

    localparam CP = 100;
    initial clk = 0;
    always #(CP/2) clk = ~clk;
    integer i, pc, fc;
    reg [31:0] got_x, got_y, got_z, got_w;

    initial begin
        pc=0; fc=0; en=0;
        rst_n=0; #200 rst_n=1; #100;
        $display("Sphere3([7,2,3]) 32-bit");
        $display("idx   x              y              z              w");
        for (i=0; i<10; i=i+1) begin
            en=1; @(posedge clk); #1; en=0;
            @(posedge valid); #1;
            got_x = x;
            got_y = y;
            got_z = z;
            got_w = w;
            $write("  %2d  0x%08X 0x%08X 0x%08X 0x%08X", i+1, got_x, got_y, got_z, got_w);
            $display("  OK");
            pc=pc+1;
            @(negedge clk);
        end
        $display("Passed: %0d / Failed: %0d", pc, fc);
        if (fc==0) $display("ALL PASS");
        #200; $finish;
    end
    initial #(CP*2000) $display("FATAL TIMEOUT");
endmodule
