module circle_3_32 (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       en,
    output wire [31:0] cos,
    output wire [31:0] sin,
    output wire       valid
);
    wire [31:0] r; wire rv; wire [31:0] a;
    vdc_3_ilds_32 u0(.clk(clk),.rst_n(rst_n),.en(en),.vdc_out(r),.valid(rv));
    assign a = (r * 64'd4766826496) >> 32;
    cordic_32 u1(.clk(clk),.rst_n(rst_n),.en(rv),.angle(a),.cos(cos),.sin(sin),.valid(valid));
endmodule
