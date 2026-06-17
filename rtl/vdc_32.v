module vdc_32 (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       en,
    output wire [31:0] vdc_out,
    output reg        valid
);

    reg [31:0] cnt;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt    <= 32'd0;
            valid  <= 1'b0;
        end else if (en) begin
            cnt    <= cnt + 32'd1;
            valid  <= 1'b1;
        end else begin
            valid  <= 1'b0;
        end
    end

    assign vdc_out = {
        cnt[ 0], cnt[ 1], cnt[ 2], cnt[ 3],
        cnt[ 4], cnt[ 5], cnt[ 6], cnt[ 7],
        cnt[ 8], cnt[ 9], cnt[10], cnt[11],
        cnt[12], cnt[13], cnt[14], cnt[15],
        cnt[16], cnt[17], cnt[18], cnt[19],
        cnt[20], cnt[21], cnt[22], cnt[23],
        cnt[24], cnt[25], cnt[26], cnt[27],
        cnt[28], cnt[29], cnt[30], cnt[31]
    };

endmodule
