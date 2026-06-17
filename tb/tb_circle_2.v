`timescale 1 ns / 1 ps

module tb_circle_2;
    reg clk, rst_n, en;
    wire [15:0] cos, sin;
    wire valid;
    circle_2 dut(.*);

    localparam integer NX = 12;
    reg [15:0] ec[0:NX-1], es[0:NX-1];

    initial begin
        ec[ 0]=16'h8000; es[ 0]=16'h0000;
        ec[ 1]=16'h0000; es[ 1]=16'h7FFF;
        ec[ 2]=16'h0000; es[ 2]=16'h8000;
        ec[ 3]=16'h5A82; es[ 3]=16'h5A82;
        ec[ 4]=16'hA57E; es[ 4]=16'hA57E;
        ec[ 5]=16'hA57E; es[ 5]=16'h5A82;
        ec[ 6]=16'h5A82; es[ 6]=16'hA57E;
        ec[ 7]=16'h7642; es[ 7]=16'h30FC;
        ec[ 8]=16'h89BE; es[ 8]=16'hCF04;
        ec[ 9]=16'hCF04; es[ 9]=16'h7642;
        ec[10]=16'h30FC; es[10]=16'h89BE;
        ec[11]=16'h30FC; es[11]=16'h7642;
    end

    localparam CP = 100;
    initial clk = 0;
    always #(CP/2) clk = ~clk;

    integer pc, fc, i, j;
    reg found;

    initial begin
        pc=0; fc=0; en=0;
        rst_n=0; #200 rst_n=1; #100;

        $display("------------------------------------------------------------");
        $display("  Circle<2>  CORDIC-based");
        $display("------------------------------------------------------------");
        $display("  idx   exp_cos  got_cos  exp_sin  got_sin");
        $display("------------------------------------------------------------");

        for (i=0; i<NX; i=i+1) begin
            en=1; @(posedge clk); en=0;
            found=0;
            for (j=0; j<30; j=j+1) begin
                @(posedge clk); #1;
                if (valid) begin
                    $write("  %2d | 0x%04X  0x%04X | 0x%04X  0x%04X", i+1, ec[i], cos, es[i], sin);
                    if (cos==ec[i] && sin==es[i]) begin $display("  PASS"); pc=pc+1; end
                    else begin $display("  FAIL (cos exp=0x%04X sin exp=0x%04X)", ec[i], es[i]); fc=fc+1; end
                    found=1; j=30;
                end
            end
            if (!found) begin $display("  %2d |  TIMEOUT", i+1); fc=fc+1; end
        end

        $display("------------------------------------------------------------");
        $display("  Passed: %0d  /  Failed: %0d", pc, fc);
        if (fc==0) $display("  *** ALL TESTS PASSED ***");
        else       $display("  *** SOME TESTS FAILED ***");
        $display("------------------------------------------------------------");
        #200; $finish;
    end

    initial #(CP*500) begin $display("FATAL TIMEOUT"); $finish; end
    initial begin $dumpfile("tb_circle_2.vcd"); $dumpvars(0, tb_circle_2); end
endmodule
