module disk_23 (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       en,
    output wire [15:0] x,
    output wire [15:0] y,
    output reg        valid
);

    wire [15:0] cos, sin;
    wire        circle_valid;

    circle_2_16 u_circle (
        .clk   (clk),
        .rst_n (rst_n),
        .en    (en),
        .cos   (cos),
        .sin   (sin),
        .valid (circle_valid)
    );

    wire [15:0] raw;
    wire        raw_valid;

    vdc_3_ilds u_vdc3 (
        .clk    (clk),
        .rst_n  (rst_n),
        .en     (en),
        .vdc_out(raw),
        .valid  (raw_valid)
    );

    wire [15:0] radius;
    wire        sqrt_valid;

    wire [15:0] raw_scaled = (raw * 32'd72736) >> 16;

    cordic_sqrt_16 u_sqrt (
        .clk     (clk),
        .rst_n   (rst_n),
        .en      (raw_valid),
        .x_in    (raw_scaled),
        .sqrt_out(radius),
        .valid   (sqrt_valid)
    );

    // Multipliers: disk_x = radius * cos, disk_y = radius * sin
    // radius: U0.16, cos/sin: Q1.15
    // product >> 16 gives Q1.15 result
    wire signed [31:0] prod_x = $signed({1'b0, radius}) * $signed(cos);
    wire signed [31:0] prod_y = $signed({1'b0, radius}) * $signed(sin);

    reg [1:0] state;
    reg       circle_done, sqrt_done;
    localparam S_IDLE = 0, S_WAIT = 1, S_DONE = 2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid <= 0; state <= S_IDLE;
            circle_done <= 0; sqrt_done <= 0;
        end else case (state)
            S_IDLE: if (en) begin
                circle_done <= 0; sqrt_done <= 0;
                state <= S_WAIT;
            end
            S_WAIT: begin
                if (circle_valid) circle_done <= 1;
                if (sqrt_valid) sqrt_done <= 1;
                if (circle_done && sqrt_done) begin
                    valid <= 1;
                    state <= S_DONE;
                end
            end
            S_DONE: begin
                valid <= 0;
                state <= S_IDLE;
            end
        endcase
    end

    assign x = prod_x >>> 16;
    assign y = prod_y >>> 16;

endmodule
