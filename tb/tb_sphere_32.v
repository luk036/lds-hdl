`timescale 1 ns / 1 ps
module tb_sphere_32;
    reg clk, rst_n, en;
    wire [31:0] x, y, z;
    wire valid;
    sphere_32 dut(.*);

    localparam CP = 100;
    initial clk = 0;
    always #(CP/2) clk = ~clk;
    integer i, pc, fc;
    reg [31:0] got_x, got_y, got_z;

    initial begin
        pc=0; fc=0; en=0;
        rst_n=0; #200 rst_n=1; #100;
        $display("Sphere<2,3> 32-bit");
        $display("idx   x              y              z");
        for (i=0; i<10; i=i+1) begin
            en=1; @(posedge clk); #1; en=0;
            @(posedge valid); #1;
            got_x = x;
            got_y = y;
            got_z = z;
            $write("  %2d  0x%08X 0x%08X 0x%08X", i+1, got_x, got_y, got_z);
            $display("  OK");
            pc=pc+1;
            @(negedge clk);
        end
        $display("Passed: %0d / Failed: %0d", pc, fc);
        if (fc==0) $display("ALL PASS");
        #200; $finish;
    end
    initial #(CP*500) $display("FATAL TIMEOUT");
endmodule
