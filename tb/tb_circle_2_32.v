`timescale 1 ns / 1 ps
module tb_circle_2_32;
    reg clk, rst_n, en;
    wire [31:0] cos, sin;
    wire valid;
    circle_2_32 dut(.*);
    localparam integer NX = 12;
    reg [31:0] ec[0:NX-1], es[0:NX-1];
    initial begin
        ec[ 0]=32'h80000000; es[ 0]=32'h00000000;
        ec[ 1]=32'h00000000; es[ 1]=32'h7FFFFFFF;
        ec[ 2]=32'h00000000; es[ 2]=32'h80000000;
        ec[ 3]=32'h5A82799A; es[ 3]=32'h5A82799A;
        ec[ 4]=32'hA57D8666; es[ 4]=32'hA57D8666;
        ec[ 5]=32'hA57D8666; es[ 5]=32'h5A82799A;
        ec[ 6]=32'h5A82799A; es[ 6]=32'hA57D8666;
        ec[ 7]=32'h7641AF3D; es[ 7]=32'h30FBC54D;
        ec[ 8]=32'h89BE50C3; es[ 8]=32'hCF043AB3;
        ec[ 9]=32'hCF043AB3; es[ 9]=32'h7641AF3D;
        ec[10]=32'h30FBC54D; es[10]=32'h89BE50C3;
        ec[11]=32'h30FBC54D; es[11]=32'h7641AF3D;
    end
    localparam CP = 100;
    initial clk = 0;
    always #(CP/2) clk = ~clk;
    integer pc, fc, i;
    integer cerr, serr;
    initial begin
        pc=0; fc=0; en=0;
        rst_n=0; #200 rst_n=1; #100;
        $display("Circle<2> CORDIC 32-bit");
        $display("idx  cos          sin          err_c   err_s");
        for (i=0; i<NX; i=i+1) begin
            en=1; @(posedge clk); #1; en=0;
            @(posedge valid);
            #1;
            cerr = $signed(cos) - $signed(ec[i]);
            if (cerr < 0) cerr = -cerr;
            serr = $signed(sin) - $signed(es[i]);
            if (serr < 0) serr = -serr;
            $write("  %2d  0x%08X 0x%08X  %6d %6d", i+1, cos, sin, cerr, serr);
            if (cerr<50000 && serr<50000) begin $display("  PASS"); pc=pc+1; end
            else begin $display("  FAIL"); fc=fc+1; end
            @(negedge clk);
        end
        $display("Passed: %0d / Failed: %0d", pc, fc);
        if (fc==0) $display("ALL PASS");
        #200; $finish;
    end
    initial #(CP*800) $display("FATAL TIMEOUT");
endmodule
