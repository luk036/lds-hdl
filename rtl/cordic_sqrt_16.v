module cordic_sqrt_16 (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       en,
    input  wire [15:0] x_in,
    output reg  [15:0] sqrt_out,
    output reg        valid
);

    reg [4:0] shift_rom [0:19];
    initial begin
        shift_rom[ 0]=5'd1;  shift_rom[ 1]=5'd2;
        shift_rom[ 2]=5'd3;  shift_rom[ 3]=5'd4;
        shift_rom[ 4]=5'd4;  shift_rom[ 5]=5'd5;
        shift_rom[ 6]=5'd6;  shift_rom[ 7]=5'd7;
        shift_rom[ 8]=5'd8;  shift_rom[ 9]=5'd9;
        shift_rom[10]=5'd10; shift_rom[11]=5'd11;
        shift_rom[12]=5'd12; shift_rom[13]=5'd13;
        shift_rom[14]=5'd13; shift_rom[15]=5'd14;
        shift_rom[16]=5'd15; shift_rom[17]=5'd16;
        shift_rom[18]=5'd17; shift_rom[19]=5'd18;
    end

    // 1/K_h in Q2.16: round(1/0.828159 * 2^16) = 79124
    localparam [31:0] INV_KH = 32'd79124;

    reg [4:0]  iter;
    reg signed [17:0] x, y;
    reg [15:0] norm_val;
    reg [2:0]  norm_shift;
    reg        busy;
    wire signed [47:0] scaled = $signed(x) * $signed(INV_KH);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sqrt_out <= 0; valid <= 0; busy <= 0;
            x <= 0; y <= 0; iter <= 0;
            norm_val <= 0; norm_shift <= 0;
        end else if (!busy && en) begin
            if (x_in < 16'h0100) begin
                norm_val <= x_in << 6; norm_shift <= 3;
            end else if (x_in < 16'h0400) begin
                norm_val <= x_in << 4; norm_shift <= 2;
            end else if (x_in < 16'h1000) begin
                norm_val <= x_in << 2; norm_shift <= 1;
            end else begin
                norm_val <= x_in; norm_shift <= 0;
            end
            busy <= 1; valid <= 0; iter <= 0;
        end else if (busy) begin
            if (iter == 0) begin
                x <= norm_val + 18'd16384;
                y <= norm_val - 18'd16384;
                iter <= 1;
            end else if (iter <= 5'd20) begin
                if (!y[17]) begin
                    x <= x - (y >>> shift_rom[iter-1]);
                    y <= y - (x >>> shift_rom[iter-1]);
                end else begin
                    x <= x + (y >>> shift_rom[iter-1]);
                    y <= y + (x >>> shift_rom[iter-1]);
                end
                iter <= iter + 1;
            end else begin
                sqrt_out <= (scaled >>> (5'd16 + {2'd0, norm_shift}));
                busy <= 0; valid <= 1;
            end
        end else begin
            valid <= 0;
        end
    end

endmodule
