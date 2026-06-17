module sphere_23 (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       en,
    output wire [15:0] x,
    output wire [15:0] y,
    output wire [15:0] z,
    output reg        valid
);

    // cosphi = 2*VdC<2> - 1, mapped to [-1, 1] in Q1.15
    wire [15:0] raw_phi;
    wire        raw_phi_valid;
    vdc_16 u_vdc (.clk(clk), .rst_n(rst_n), .en(en), .vdc_out(raw_phi), .valid(raw_phi_valid));

    wire [15:0] cosphi = raw_phi - 16'h8000;

    // Circle<3> for the point on the circle cross-section
    wire [15:0] cx, cy;
    wire        circle_valid;
    circle_3_16 u_circle (.clk(clk), .rst_n(rst_n), .en(en), .cos(cx), .sin(cy), .valid(circle_valid));

    // sinphi = sqrt(1 - cosphi^2)
    // cosphi is Q1.15, cosphi^2 is Q2.30
    // sqrt(1 - cosphi^2): cosphi = 2*VdC-1, so |cosphi| = |raw_phi - 0x8000|
    wire [15:0] abs_cosphi = (raw_phi > 16'h8000) ? (raw_phi - 16'h8000) : (16'h8000 - raw_phi);
    wire [31:0] diff_sq = abs_cosphi * abs_cosphi;
    wire [31:0] remainder = 32'h40000000 - diff_sq;
    wire [15:0] sqrt_in = (remainder > 32'h3FFFFFFF) ? 16'd65535 : (remainder >> 14);

    wire [15:0] sinphi;
    wire        sqrt_valid;
    cordic_sqrt_16 u_sqrt (.clk(clk), .rst_n(rst_n), .en(raw_phi_valid), .x_in(sqrt_in), .sqrt_out(sinphi), .valid(sqrt_valid));

    // Multipliers: sinphi (U0.16) * cx/cy (Q1.15) → Q1.15
    wire signed [31:0] prod_x = $signed({16'd0, sinphi}) * $signed({{16{cx[15]}}, cx});
    wire signed [31:0] prod_y = $signed({16'd0, sinphi}) * $signed({{16{cy[15]}}, cy});

    // Handshake: wait for both circle and sqrt
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

    assign x = prod_x >>> 16;
    assign y = prod_y >>> 16;
    assign z = cosphi;

endmodule
