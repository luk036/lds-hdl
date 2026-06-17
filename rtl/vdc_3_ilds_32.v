module vdc_3_ilds_32 (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       en,
    output reg  [31:0] vdc_out,
    output reg        valid
);

    wire [31:0] factor [0:19];
    assign factor[ 0] = 32'd1162261467;
    assign factor[ 1] = 32'd 387420489;
    assign factor[ 2] = 32'd 129140163;
    assign factor[ 3] = 32'd  43046721;
    assign factor[ 4] = 32'd  14348907;
    assign factor[ 5] = 32'd   4782969;
    assign factor[ 6] = 32'd   1594323;
    assign factor[ 7] = 32'd    531441;
    assign factor[ 8] = 32'd    177147;
    assign factor[ 9] = 32'd     59049;
    assign factor[10] = 32'd     19683;
    assign factor[11] = 32'd      6561;
    assign factor[12] = 32'd      2187;
    assign factor[13] = 32'd       729;
    assign factor[14] = 32'd       243;
    assign factor[15] = 32'd        81;
    assign factor[16] = 32'd        27;
    assign factor[17] = 32'd         9;
    assign factor[18] = 32'd         3;
    assign factor[19] = 32'd         1;

    function [1:0] mod3;
        input [31:0] x;
        reg [17:0] s;
        begin
            s = {2'b0, x[ 1:0]} + {2'b0, x[ 3:2]} + {2'b0, x[ 5:4]}
              + {2'b0, x[ 7:6]} + {2'b0, x[ 9:8]} + {2'b0, x[11:10]}
              + {2'b0, x[13:12]} + {2'b0, x[15:14]} + {2'b0, x[17:16]}
              + {2'b0, x[19:18]} + {2'b0, x[21:20]} + {2'b0, x[23:22]}
              + {2'b0, x[25:24]} + {2'b0, x[27:26]} + {2'b0, x[29:28]}
              + {2'b0, x[31:30]};
            s = s[1:0] + {2'b0, s[4:2]};
            s = s[1:0] + {2'b0, s[4:2]};
            if (s >= 3) s = s - 3;
            mod3 = s[1:0];
        end
    endfunction

    function [31:0] div3;
        input [31:0] x;
        begin
            div3 = (x * 64'h0000000155555556) >> 34;
        end
    endfunction

    reg [31:0] cnt;
    reg [31:0] work;
    reg [31:0] accum;
    reg [4:0]  idx;
    reg        busy;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt    <= 32'd0;
            vdc_out <= 32'd0;
            valid  <= 1'b0;
            busy   <= 1'b0;
            work   <= 32'd0;
            accum  <= 32'd0;
            idx    <= 5'd0;
        end else if (!busy && en) begin
            cnt    <= cnt + 32'd1;
            work   <= cnt + 32'd1;
            accum  <= 32'd0;
            idx    <= 5'd0;
            busy   <= 1'b1;
            valid  <= 1'b0;
        end else if (busy) begin
            if (work == 32'd0 || idx > 5'd19) begin
                vdc_out <= accum;
                busy    <= 1'b0;
                valid   <= 1'b1;
            end else begin
                accum <= accum + mod3(work) * factor[idx];
                work  <= div3(work);
                idx   <= idx + 5'd1;
                valid <= 1'b0;
            end
        end else begin
            valid <= 1'b0;
        end
    end

endmodule
