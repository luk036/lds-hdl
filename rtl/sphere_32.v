module sphere_32 (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       en,
    output wire [31:0] x,
    output wire [31:0] y,
    output wire [31:0] z,
    output reg        valid
);

    wire [31:0] raw_phi;
    wire        raw_phi_valid;
    vdc_32 u_vdc (.clk(clk), .rst_n(rst_n), .en(en), .vdc_out(raw_phi), .valid(raw_phi_valid));

    wire [31:0] cosphi = raw_phi - 32'h80000000;

    wire [31:0] cx, cy;
    wire        circle_valid;
    circle_3_32 u_circle (.clk(clk), .rst_n(rst_n), .en(en), .cos(cx), .sin(cy), .valid(circle_valid));

    wire [31:0] abs_cosphi = (raw_phi > 32'h80000000) ? (raw_phi - 32'h80000000) : (32'h80000000 - raw_phi);
    wire [63:0] diff_sq = {32'd0, abs_cosphi} * {32'd0, abs_cosphi};
    wire [63:0] remainder = 64'h4000000000000000 - diff_sq;
    wire [31:0] sqrt_in = (remainder > 64'h3FFFFFFFFFFFFFFF) ? 32'hFFFFFFFF : (remainder >> 30);

    wire [31:0] sinphi;
    wire        sqrt_valid;
    cordic_sqrt_32 u_sqrt (.clk(clk), .rst_n(rst_n), .en(raw_phi_valid), .x_in(sqrt_in), .sqrt_out(sinphi), .valid(sqrt_valid));

    wire signed [63:0] prod_x = $signed({32'd0, sinphi}) * $signed({{32{cx[31]}}, cx});
    wire signed [63:0] prod_y = $signed({32'd0, sinphi}) * $signed({{32{cy[31]}}, cy});

    reg [1:0] state;
    reg       circle_done, sqrt_done;
    localparam S_IDLE = 0, S_WAIT = 1, S_DONE = 2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid <= 0; state <= S_IDLE;
            circle_done <= 0; sqrt_done <= 0;
        end else begin
            if (circle_valid) circle_done <= 1;
            if (sqrt_valid) sqrt_done <= 1;
            case (state)
                S_IDLE: if (en) begin
                    state <= S_WAIT;
                end
                S_WAIT: if (circle_done && sqrt_done) begin
                    valid <= 1; state <= S_DONE;
                    circle_done <= 0; sqrt_done <= 0;
                end
                S_DONE: begin
                    valid <= 0;
                    if (en) begin state <= S_WAIT; end
                    else begin state <= S_IDLE; end
                end
            endcase
        end
    end

    assign x = prod_x >>> 32;
    assign y = prod_y >>> 32;
    assign z = cosphi;

endmodule
