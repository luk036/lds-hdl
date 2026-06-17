module cordic_16 (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       en,
    input  wire [15:0] angle,
    output reg  [15:0] cos,
    output reg  [15:0] sin,
    output reg        valid
);

    reg [15:0] atan [0:15];
    initial begin
        atan[ 0]=16'd8192; atan[ 1]=16'd4836;
        atan[ 2]=16'd2555; atan[ 3]=16'd1297;
        atan[ 4]=16'd651;  atan[ 5]=16'd326;
        atan[ 6]=16'd163;  atan[ 7]=16'd81;
        atan[ 8]=16'd41;   atan[ 9]=16'd20;
        atan[10]=16'd10;   atan[11]=16'd5;
        atan[12]=16'd3;    atan[13]=16'd1;
        atan[14]=16'd1;    atan[15]=16'd0;
    end

    localparam [17:0] XI = 18'd79589;

    reg [3:0]  iter;
    reg signed [17:0] x, y, x_next, y_next;
    reg [15:0] z;
    reg [1:0]  quad;
    reg        busy;
    reg        neg_x, neg_y;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cos <= 0; sin <= 0; valid <= 0; busy <= 0;
            x <= 0; y <= 0; x_next <= 0; y_next <= 0; z <= 0; iter <= 0;
            quad <= 0; neg_x <= 0; neg_y <= 0;
        end else if (!busy && en) begin
            quad <= angle[15:14];
            case (angle[15:14])
                2'b00: begin z <= {2'b00, angle[13:0]}; neg_x <= 0; neg_y <= 0; end
                2'b01: begin z <= 16'h4000 - {2'b00, angle[13:0]}; neg_x <= 1; neg_y <= 0; end
                2'b10: begin z <= {2'b00, angle[13:0]}; neg_x <= 1; neg_y <= 1; end
                2'b11: begin z <= 16'h4000 - {2'b00, angle[13:0]}; neg_x <= 0; neg_y <= 1; end
            endcase
            x <= XI; y <= 0; iter <= 0; busy <= 1; valid <= 0;
        end else if (busy) begin
            if (iter < 4'd15) begin
                if (!z[15]) begin
                    x_next = x - (y >>> iter);
                    y_next = y + (x >>> iter);
                    z <= z - atan[iter];
                end else begin
                    x_next = x + (y >>> iter);
                    y_next = y - (x >>> iter);
                    z <= z + atan[iter];
                end
                x <= x_next; y <= y_next;
                iter <= iter + 1;
            end else begin
                cos <= neg_x ? (~x[17:2] + 1'b1) : x[17:2];
                sin <= neg_y ? (~y[17:2] + 1'b1) : y[17:2];
                busy <= 0; valid <= 1;
            end
        end else begin
            valid <= 0;
        end
    end

endmodule
