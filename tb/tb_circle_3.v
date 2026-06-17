`timescale 1 ns / 1 ps

module tb_circle_3;
    reg clk, rst_n, en;
    wire [15:0] cos, sin;
    wire valid;
    circle_3 dut(.*);

    localparam integer NX = 12;
    reg [15:0] ec[0:NX-1], es[0:NX-1];

    initial begin
        ec[ 0]=16'hC000; es[ 0]=16'h6EDA;
        ec[ 1]=16'hC000; es[ 1]=16'h9126;
        ec[ 2]=16'h620E; es[ 2]=16'h5247;
        ec[ 3]=16'h87B8; es[ 3]=16'h2BC7;
        ec[ 4]=16'h163A; es[ 4]=16'h81F2;
        ec[ 5]=16'h163A; es[ 5]=16'h7E0E;
        ec[ 6]=16'h87B8; es[ 6]=16'hD439;
        ec[ 7]=16'h620E; es[ 7]=16'hADB9;
        ec[ 8]=16'h7C8D; es[ 8]=16'h1D85;
        ec[ 9]=16'hA829; es[ 9]=16'h5D1B;
        ec[10]=16'hDB4A; es[10]=16'h8561;
        ec[11]=16'h4C70; es[11]=16'h66AC;
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
        $display("  Circle<3>  CORDIC-based");
        $display("------------------------------------------------------------");
        $display("  idx   exp_cos  got_cos  exp_sin  got_sin");
        $display("------------------------------------------------------------");

        for (i=0; i<NX; i=i+1) begin
            en=1; @(posedge clk); en=0;
            found=0;
            for (j=0; j<40; j=j+1) begin
                @(posedge clk); #1;
                if (valid) begin
                    $write("  %2d | 0x%04X  0x%04X | 0x%04X  0x%04X", i+1, ec[i], cos, es[i], sin);
                    if (cos==ec[i] && sin==es[i]) begin $display("  PASS"); pc=pc+1; end
                    else begin $display("  FAIL (cos exp=0x%04X sin exp=0x%04X)", ec[i], es[i]); fc=fc+1; end
                    found=1; j=40;
                end
            end
            if (!found) begin $display("  %2d |  TIMEOUT", i+1); fc=fc+1; end
        end

        $display("------------------------------------------------------------");
        $display("  Passed: %0d / Failed: %0d", pc, fc);
        if (fc==0) $display("  *** ALL TESTS PASSED ***");
        else       $display("  *** SOME TESTS FAILED ***");
        $display("------------------------------------------------------------");
        #200; $finish;
    end

    initial #(CP*500) begin $display("FATAL TIMEOUT"); $finish; end
    initial begin $dumpfile("tb_circle_3.vcd"); $dumpvars(0, tb_circle_3); end
endmodule
