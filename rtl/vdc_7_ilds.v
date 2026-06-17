module vdc_7_ilds (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       en,
    output reg  [15:0] vdc_out,
    output reg        valid
);

    wire [15:0] factor [0:4];
    assign factor[0] = 16'd2401;
    assign factor[1] = 16'd343;
    assign factor[2] = 16'd49;
    assign factor[3] = 16'd7;
    assign factor[4] = 16'd1;

    function [2:0] mod7;
        input [15:0] x;
        reg [15:0] s;
        begin
            s = {3'b0, x[ 2:0]} + {3'b0, x[ 5:3]} + {3'b0, x[ 8:6]}
              + {3'b0, x[11:9]} + {3'b0, x[14:12]} + {3'b0, x[15]};
            s = s[2:0] + {3'b0, s[5:3]};
            s = s[2:0] + {3'b0, s[5:3]};
            if (s >= 7) s = s - 7;
            mod7 = s[2:0];
        end
    endfunction

    function [15:0] div7;
        input [15:0] x;
        reg [7:0] hi, lo;
        reg [15:0] rem_part;
        begin
            hi = x[15:8];
            lo = x[7:0];
            rem_part = hi * 4 + lo;
            div7 = hi * 36 + ((rem_part * 32'h00004925) >> 17);
        end
    endfunction

    reg [15:0] cnt;
    reg [15:0] work;
    reg [31:0] accum;
    reg [2:0]  idx;
    reg        busy;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt    <= 16'd0;
            vdc_out <= 16'd0;
            valid  <= 1'b0;
            busy   <= 1'b0;
            work   <= 16'd0;
            accum  <= 32'd0;
            idx    <= 3'd0;
        end else if (!busy && en) begin
            cnt    <= cnt + 16'd1;
            work   <= cnt + 16'd1;
            accum  <= 32'd0;
            idx    <= 3'd0;
            busy   <= 1'b1;
            valid  <= 1'b0;
        end else if (busy) begin
            if (work == 16'd0 || idx > 3'd4) begin
                vdc_out <= accum[15:0];
                busy    <= 1'b0;
                valid   <= 1'b1;
            end else begin
                accum <= accum + mod7(work) * factor[idx];
                work  <= div7(work);
                idx   <= idx + 3'd1;
                valid <= 1'b0;
            end
        end else begin
            valid <= 1'b0;
        end
    end

endmodule
