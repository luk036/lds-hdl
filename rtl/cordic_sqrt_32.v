module cordic_sqrt_32 (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       en,
    input  wire [31:0] x_in,
    output reg  [31:0] sqrt_out,
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

    localparam [33:0] INV_KH = 34'd5186160416;

    reg [5:0]  iter;
    reg signed [33:0] x, y;
    reg [31:0] norm_val;
    reg [2:0]  norm_shift;
    reg        busy;
    wire signed [67:0] scaled = $signed(x) * $signed(INV_KH);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sqrt_out <= 0; valid <= 0; busy <= 0;
            x <= 0; y <= 0; iter <= 0;
            norm_val <= 0; norm_shift <= 0;
        end else if (!busy && en) begin
            if (x_in < 32'h00001000) begin
                norm_val <= x_in << 14; norm_shift <= 7;
            end else if (x_in < 32'h00004000) begin
                norm_val <= x_in << 12; norm_shift <= 6;
            end else if (x_in < 32'h00010000) begin
                norm_val <= x_in << 10; norm_shift <= 5;
            end else if (x_in < 32'h00040000) begin
                norm_val <= x_in << 8; norm_shift <= 4;
            end else if (x_in < 32'h01000000) begin
                norm_val <= x_in << 6; norm_shift <= 3;
            end else if (x_in < 32'h04000000) begin
                norm_val <= x_in << 4; norm_shift <= 2;
            end else if (x_in < 32'h10000000) begin
                norm_val <= x_in << 2; norm_shift <= 1;
            end else begin
                norm_val <= x_in; norm_shift <= 0;
            end
            busy <= 1; valid <= 0; iter <= 0;
        end else if (busy) begin
            if (iter == 0) begin
                x <= norm_val + 34'd1073741824;
                y <= norm_val - 34'd1073741824;
                iter <= 1;
            end else if (iter <= 6'd20) begin
                if (!y[33]) begin
                    x <= x - (y >>> shift_rom[iter-1]);
                    y <= y - (x >>> shift_rom[iter-1]);
                end else begin
                    x <= x + (y >>> shift_rom[iter-1]);
                    y <= y + (x >>> shift_rom[iter-1]);
                end
                iter <= iter + 1;
            end else begin
                sqrt_out <= scaled >>> (6'd32 + {3'd0, norm_shift});
                busy <= 0; valid <= 1;
            end
        end else begin
            valid <= 0;
        end
    end

endmodule
