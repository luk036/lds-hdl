module vdc_3_ilds (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       en,
    output reg  [15:0] vdc_out,
    output reg        valid
);

    wire [15:0] factor [0:9];
    assign factor[0] = 16'd19683;
    assign factor[1] = 16'd6561;
    assign factor[2] = 16'd2187;
    assign factor[3] = 16'd729;
    assign factor[4] = 16'd243;
    assign factor[5] = 16'd81;
    assign factor[6] = 16'd27;
    assign factor[7] = 16'd9;
    assign factor[8] = 16'd3;
    assign factor[9] = 16'd1;

    function [1:0] mod3;
        input [15:0] x;
        reg [17:0] s;
        begin
            s = {2'b0, x[ 1:0]} + {2'b0, x[ 3:2]} + {2'b0, x[ 5:4]}
              + {2'b0, x[ 7:6]} + {2'b0, x[ 9:8]} + {2'b0, x[11:10]}
              + {2'b0, x[13:12]} + {2'b0, x[15:14]};
            s = s[1:0] + {2'b0, s[4:2]};
            s = s[1:0] + {2'b0, s[4:2]};
            if (s >= 3) s = s - 3;
            mod3 = s[1:0];
        end
    endfunction

    function [15:0] div3;
        input [15:0] x;
        begin
            div3 = (x * 32'h0000AAAB) >> 17;
        end
    endfunction

    reg [15:0] cnt;
    reg [15:0] work;
    reg [31:0] accum;
    reg [3:0]  idx;
    reg        busy;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt    <= 16'd0;
            vdc_out <= 16'd0;
            valid  <= 1'b0;
            busy   <= 1'b0;
            work   <= 16'd0;
            accum  <= 32'd0;
            idx    <= 4'd0;
        end else if (!busy && en) begin
            cnt    <= cnt + 16'd1;
            work   <= cnt + 16'd1;
            accum  <= 32'd0;
            idx    <= 4'd0;
            busy   <= 1'b1;
            valid  <= 1'b0;
        end else if (busy) begin
            if (work == 16'd0 || idx > 4'd9) begin
                vdc_out <= accum[15:0];
                busy    <= 1'b0;
                valid   <= 1'b1;
            end else begin
                accum <= accum + mod3(work) * factor[idx];
                work  <= div3(work);
                idx   <= idx + 4'd1;
                valid <= 1'b0;
            end
        end else begin
            valid <= 1'b0;
        end
    end

endmodule
