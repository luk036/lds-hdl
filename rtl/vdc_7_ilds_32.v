module vdc_7_ilds_32 (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       en,
    output reg  [31:0] vdc_out,
    output reg        valid
);

    wire [31:0] factor [0:10];
    assign factor[ 0] = 32'd282475249;
    assign factor[ 1] = 32'd 40353607;
    assign factor[ 2] = 32'd  5764801;
    assign factor[ 3] = 32'd   823543;
    assign factor[ 4] = 32'd   117649;
    assign factor[ 5] = 32'd    16807;
    assign factor[ 6] = 32'd     2401;
    assign factor[ 7] = 32'd      343;
    assign factor[ 8] = 32'd       49;
    assign factor[ 9] = 32'd        7;
    assign factor[10] = 32'd        1;

    function [2:0] mod7;
        input [31:0] x;
        reg [15:0] s;
        begin
            s = {3'b0, x[ 2:0]} + {3'b0, x[ 5:3]} + {3'b0, x[ 8:6]}
              + {3'b0, x[11:9]} + {3'b0, x[14:12]} + {3'b0, x[17:15]}
              + {3'b0, x[20:18]} + {3'b0, x[23:21]} + {3'b0, x[26:24]}
              + {3'b0, x[29:27]} + {3'b0, x[31:30]};
            s = s[2:0] + {3'b0, s[6:3]};
            s = s[2:0] + {3'b0, s[5:3]};
            if (s >= 7) s = s - 7;
            mod7 = s[2:0];
        end
    endfunction

    function [31:0] div7;
        input [31:0] x;
        begin
            div7 = (x * 64'h0000000124924925) >> 35;
        end
    endfunction

    reg [31:0] cnt;
    reg [31:0] work;
    reg [31:0] accum;
    reg [3:0]  idx;
    reg        busy;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt    <= 32'd0;
            vdc_out <= 32'd0;
            valid  <= 1'b0;
            busy   <= 1'b0;
            work   <= 32'd0;
            accum  <= 32'd0;
            idx    <= 4'd0;
        end else if (!busy && en) begin
            cnt    <= cnt + 32'd1;
            work   <= cnt + 32'd1;
            accum  <= 32'd0;
            idx    <= 4'd0;
            busy   <= 1'b1;
            valid  <= 1'b0;
        end else if (busy) begin
            if (work == 32'd0 || idx > 4'd10) begin
                vdc_out <= accum;
                busy    <= 1'b0;
                valid   <= 1'b1;
            end else begin
                accum <= accum + mod7(work) * factor[idx];
                work  <= div7(work);
                idx   <= idx + 4'd1;
                valid <= 1'b0;
            end
        end else begin
            valid <= 1'b0;
        end
    end

endmodule
