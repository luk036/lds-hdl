module cordic_32 (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       en,
    input  wire [31:0] angle,
    output reg  [31:0] cos,
    output reg  [31:0] sin,
    output reg        valid
);

    reg [31:0] atan [0:30];
    initial begin
        atan[ 0]=32'd536870912; atan[ 1]=32'd316933406;
        atan[ 2]=32'd167458907; atan[ 3]=32'd85004756;
        atan[ 4]=32'd42667331;  atan[ 5]=32'd21354465;
        atan[ 6]=32'd10679838;  atan[ 7]=32'd5340245;
        atan[ 8]=32'd2670163;   atan[ 9]=32'd1335087;
        atan[10]=32'd667544;    atan[11]=32'd333772;
        atan[12]=32'd166886;    atan[13]=32'd83443;
        atan[14]=32'd41722;     atan[15]=32'd20861;
        atan[16]=32'd10430;     atan[17]=32'd5215;
        atan[18]=32'd2608;      atan[19]=32'd1304;
        atan[20]=32'd652;       atan[21]=32'd326;
        atan[22]=32'd163;       atan[23]=32'd81;
        atan[24]=32'd41;        atan[25]=32'd20;
        atan[26]=32'd10;        atan[27]=32'd5;
        atan[28]=32'd3;         atan[29]=32'd1;
        atan[30]=32'd1;
    end

    localparam [33:0] XI = 34'd5216262993;

    reg [4:0]  iter;
    reg signed [33:0] x, y, x_next, y_next;
    reg [31:0] z;
    reg [1:0]  quad;
    reg        busy;
    reg        neg_x, neg_y;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cos <= 0; sin <= 0; valid <= 0; busy <= 0;
            x <= 0; y <= 0; x_next <= 0; y_next <= 0; z <= 0; iter <= 0;
            quad <= 0; neg_x <= 0; neg_y <= 0;
        end else if (!busy && en) begin
            quad <= angle[31:30];
            case (angle[31:30])
                2'b00: begin z <= {2'b00, angle[29:0]}; neg_x <= 0; neg_y <= 0; end
                2'b01: begin z <= 32'h40000000 - {2'b00, angle[29:0]}; neg_x <= 1; neg_y <= 0; end
                2'b10: begin z <= {2'b00, angle[29:0]}; neg_x <= 1; neg_y <= 1; end
                2'b11: begin z <= 32'h40000000 - {2'b00, angle[29:0]}; neg_x <= 0; neg_y <= 1; end
            endcase
            x <= XI; y <= 0; iter <= 0; busy <= 1; valid <= 0;
        end else if (busy) begin
            if (iter < 5'd31) begin
                if (!z[31]) begin
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
                cos <= neg_x ? (~x[33:2] + 1'b1) : x[33:2];
                sin <= neg_y ? (~y[33:2] + 1'b1) : y[33:2];
                busy <= 0; valid <= 1;
            end
        end else begin
            valid <= 0;
        end
    end

endmodule
