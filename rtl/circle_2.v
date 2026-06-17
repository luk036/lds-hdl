module circle_2 (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       en,
    output wire [15:0] cos,
    output wire [15:0] sin,
    output wire       valid
);

    wire [15:0] angle;
    wire        vdc_valid;

    vdc_16 u_vdc (
        .clk    (clk),
        .rst_n  (rst_n),
        .en     (en),
        .vdc_out(angle),
        .valid  (vdc_valid)
    );

    cordic_iter u_cordic (
        .clk    (clk),
        .rst_n  (rst_n),
        .en     (vdc_valid),
        .angle  (angle),
        .cos    (cos),
        .sin    (sin),
        .valid  (valid)
    );

endmodule
