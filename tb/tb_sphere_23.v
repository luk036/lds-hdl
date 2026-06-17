`timescale 1 ns / 1 ps
module tb_sphere_23;
    reg clk, rst_n, en;
    wire [15:0] x, y, z;
    wire valid;
    sphere_23 dut(.*);
    localparam integer NX = 10;
    reg [15:0] ex[0:NX-1], ey[0:NX-1], ez[0:NX-1];
    initial begin
        ex[ 0]=16'hC000; ey[ 0]=16'h6EDA; ez[ 0]=16'h0000;
        ex[ 1]=16'hC893; ey[ 1]=16'hA000; ez[ 1]=16'hC000;
        ex[ 2]=16'h54EB; ey[ 2]=16'h4741; ez[ 2]=16'h4000;
        ex[ 3]=16'hB071; ey[ 3]=16'h1CF5; ez[ 3]=16'hA000;
        ex[ 4]=16'h1585; ey[ 4]=16'h85F3; ez[ 4]=16'h2000;
        ex[ 5]=16'h1585; ey[ 5]=16'h7A0D; ez[ 5]=16'hE000;
        ex[ 6]=16'hB071; ey[ 6]=16'hE30B; ez[ 6]=16'h6000;
        ex[ 7]=16'h2F78; ey[ 7]=16'hD82B; ez[ 7]=16'h9000;
        ex[ 8]=16'h7B93; ey[ 8]=16'h1D4A; ez[ 8]=16'h1000;
        ex[ 9]=16'hAE92; ey[ 9]=16'h564F; ez[ 9]=16'hD000;
    end
    localparam CP = 100;
    initial clk = 0;
    always #(CP/2) clk = ~clk;
    integer i, pc, fc, exx, eyy, ezz;
    initial begin
        pc=0; fc=0; en=0;
        rst_n=0; #200 rst_n=1; #100;
        $display("Sphere<2,3> (cosphi from VdC<2>, circle from VdC<3>)");
        $display("idx   x        y        z        err_x err_y err_z");
        for (i=0; i<NX; i=i+1) begin
            en=1; @(posedge clk); #1; en=0;
            @(posedge valid); #1;
            exx = $signed(x)-$signed(ex[i]); if(exx<0) exx=-exx;
            eyy = $signed(y)-$signed(ey[i]); if(eyy<0) eyy=-eyy;
            ezz = $signed(z)-$signed(ez[i]); if(ezz<0) ezz=-ezz;
            $write("  %2d  0x%04X 0x%04X 0x%04X  %4d %4d %4d",i+1,x,y,z,exx,eyy,ezz);
            if (exx<80 && eyy<80 && ezz<5) begin $display("  PASS"); pc=pc+1; end
            else begin $display("  FAIL"); fc=fc+1; end
            @(negedge clk);
        end
        $display("Passed: %0d / Failed: %0d", pc, fc);
        if (fc==0) $display("ALL PASS");
        #200; $finish;
    end
    initial #(CP*500) $display("FATAL TIMEOUT");
endmodule
