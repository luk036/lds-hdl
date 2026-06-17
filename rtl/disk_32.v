module disk_32 (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       en,
    output wire [31:0] x,
    output wire [31:0] y,
    output reg        valid
);

    wire [31:0] cos, sin;
    wire        circle_valid;

    circle_2_32 u_circle (
        .clk   (clk),
        .rst_n (rst_n),
        .en    (en),
        .cos   (cos),
        .sin   (sin),
        .valid (circle_valid)
    );

    wire [31:0] raw;
    wire        raw_valid;

    vdc_3_ilds_32 u_vdc3 (
        .clk    (clk),
        .rst_n  (rst_n),
        .en     (en),
        .vdc_out(raw),
        .valid  (raw_valid)
    );

    wire [31:0] radius;
    wire        sqrt_valid;

    wire [31:0] raw_scaled = (raw * 64'd4766826496) >> 32;

    cordic_sqrt_32 u_sqrt (
        .clk     (clk),
        .rst_n   (rst_n),
        .en      (raw_valid),
        .x_in    (raw_scaled),
        .sqrt_out(radius),
        .valid   (sqrt_valid)
    );

    wire signed [63:0] prod_x = $signed({32'd0, radius}) * $signed({{32{cos[31]}}, cos});
    wire signed [63:0] prod_y = $signed({32'd0, radius}) * $signed({{32{sin[31]}}, sin});

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

endmodule
