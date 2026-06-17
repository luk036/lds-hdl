`timescale 1 ns / 1 ps
module tb_circle_3_32;
    reg clk, rst_n, en;
    wire [31:0] cos, sin;
    wire valid;
    circle_3_32 dut(.*);
    localparam integer NX = 12;
    reg [31:0] ec[0:NX-1], es[0:NX-1];
    initial begin
        ec[ 0]=32'hD82F8A43; es[ 0]=32'h79A68125;
        ec[ 1]=32'h98C4B67C; es[ 1]=32'hB4524C5E;
        ec[ 2]=32'h6780238C; es[ 2]=32'h4B4F6E45;
        ec[ 3]=32'h983B5882; es[ 3]=32'h4AF0EA44;
        ec[ 4]=32'hD90DB08E; es[ 4]=32'h8611AA22;
        ec[ 5]=32'h276172FA; es[ 5]=32'h79CA9E28;
        ec[ 6]=32'h8000353C; es[ 6]=32'hFF8B4355;
        ec[ 7]=32'h283F5765; es[ 7]=32'h867E010D;
        ec[ 8]=32'h7D325255; es[ 8]=32'h1AA47667;
        ec[ 9]=32'hBFBCA5E3; es[ 9]=32'h6EB2ED93;
        ec[10]=32'hAAC809B2; es[10]=32'hA07DEFAA;
        ec[11]=32'h558EED83; es[11]=32'h5F34304B;
    end
    localparam CP = 100;
    initial clk = 0;
    always #(CP/2) clk = ~clk;
    integer pc, fc, i;
    integer cerr, serr;
    initial begin
        pc=0; fc=0; en=0;
        rst_n=0; #200 rst_n=1; #100;
        $display("Circle<3> CORDIC 32-bit");
        $display("idx  cos          sin          err_c   err_s");
        for (i=0; i<NX; i=i+1) begin
            en=1; @(posedge clk); #1; en=0;
            @(posedge valid); #1;
            cerr = $signed(cos) - $signed(ec[i]);
            if (cerr < 0) cerr = -cerr;
            serr = $signed(sin) - $signed(es[i]);
            if (serr < 0) serr = -serr;
            $write("  %2d  0x%08X 0x%08X  %6d %6d", i+1, cos, sin, cerr, serr);
            if (cerr<2000 && serr<2000) begin $display("  PASS"); pc=pc+1; end
            else begin $display("  FAIL"); fc=fc+1; end
            @(negedge clk);
        end
        $display("Passed: %0d / Failed: %0d", pc, fc);
        if (fc==0) $display("ALL PASS");
        #200; $finish;
    end
    initial #(CP*800) $display("FATAL TIMEOUT");
endmodule
