module circle_3_16 (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       en,
    output wire [15:0] cos,
    output wire [15:0] sin,
    output wire       valid
);
    wire [15:0] r; wire rv; wire [15:0] a;
    vdc_3_ilds u0(.clk(clk),.rst_n(rst_n),.en(en),.vdc_out(r),.valid(rv));
    assign a = (r * 32'd72736) >> 16;
    cordic_16 u1(.clk(clk),.rst_n(rst_n),.en(rv),.angle(a),.cos(cos),.sin(sin),.valid(valid));
endmodule
