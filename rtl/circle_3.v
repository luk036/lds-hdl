module circle_3 (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       en,
    output wire [15:0] cos,
    output wire [15:0] sin,
    output wire       valid
);

    wire [15:0] raw;
    wire        raw_valid;
    wire [15:0] angle;

    vdc_3_ilds u_vdc (
        .clk    (clk),
        .rst_n  (rst_n),
        .en     (en),
        .vdc_out(raw),
        .valid  (raw_valid)
    );

    assign angle = (raw * 32'd72736) >> 16;

    cordic_iter u_cordic (
        .clk    (clk),
        .rst_n  (rst_n),
        .en     (raw_valid),
        .angle  (angle),
        .cos    (cos),
        .sin    (sin),
        .valid  (valid)
    );

endmodule
