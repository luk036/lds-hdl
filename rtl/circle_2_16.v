module circle_2_16 (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       en,
    output wire [15:0] cos,
    output wire [15:0] sin,
    output wire       valid
);
    wire [15:0] a; wire vv;
    vdc_16 u0(.clk(clk),.rst_n(rst_n),.en(en),.vdc_out(a),.valid(vv));
    cordic_16 u1(.clk(clk),.rst_n(rst_n),.en(vv),.angle(a),.cos(cos),.sin(sin),.valid(valid));
endmodule
