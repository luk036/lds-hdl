module circle_2_32 (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       en,
    output wire [31:0] cos,
    output wire [31:0] sin,
    output wire       valid
);
    wire [31:0] a; wire vv;
    vdc_32 u0(.clk(clk),.rst_n(rst_n),.en(en),.vdc_out(a),.valid(vv));
    cordic_32 u1(.clk(clk),.rst_n(rst_n),.en(vv),.angle(a),.cos(cos),.sin(sin),.valid(valid));
endmodule
