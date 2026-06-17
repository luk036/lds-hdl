`timescale 1 ns / 1 ps
module tb_disk_23;
    reg clk, rst_n, en;
    wire [15:0] x, y;
    wire valid;
    disk_23 dut(.*);
    localparam integer NX = 10;
    reg [15:0] ex[0:NX-1], ey[0:NX-1];
    initial begin
        ex[ 0]=16'hB619; ey[ 0]=16'h0000;
        ex[ 1]=16'h0000; ey[ 1]=16'h6883;
        ex[ 2]=16'h0000; ey[ 2]=16'hD555;
        ex[ 3]=16'h3C57; ey[ 3]=16'h3C57;
        ex[ 4]=16'hB02E; ey[ 4]=16'hB02E;
        ex[ 5]=16'hD555; ey[ 5]=16'h2AAB;
        ex[ 6]=16'h4376; ey[ 6]=16'hBC8A;
        ex[ 7]=16'h6F7E; ey[ 7]=16'h2E2F;
        ex[ 8]=16'hE93E; ey[ 8]=16'hF693;
        ex[ 9]=16'hE231; ey[ 9]=16'h47F8;
    end
    localparam CP = 100;
    initial clk = 0;
    always #(CP/2) clk = ~clk;
    integer i, pc, fc, err_x, err_y;
    initial begin
        pc=0; fc=0; en=0;
        rst_n=0; #200 rst_n=1; #100;
        $display("idx   x        y        exp_x    exp_y    err_x err_y");
        for (i=0; i<NX; i=i+1) begin
            en=1; @(posedge clk); #1; en=0;
            @(posedge valid); #1;
            err_x = $signed(x) - $signed(ex[i]);
            if (err_x < 0) err_x = -err_x;
            err_y = $signed(y) - $signed(ey[i]);
            if (err_y < 0) err_y = -err_y;
            $write("  %2d  0x%04X 0x%04X  0x%04X 0x%04X  %4d %4d",
                   i+1, x, y, ex[i], ey[i], err_x, err_y);
            if (err_x < 50 && err_y < 50) begin $display("  PASS"); pc=pc+1; end
            else begin $display("  FAIL"); fc=fc+1; end
            @(negedge clk);
        end
        $display("Passed: %0d / Failed: %0d", pc, fc);
        if (fc==0) $display("ALL PASS");
        #200; $finish;
    end
    initial #(CP*500) $display("FATAL TIMEOUT");
endmodule
