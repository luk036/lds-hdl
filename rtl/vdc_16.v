// -----------------------------------------------------------------------------
// vdc_16.v
// -----------------------------------------------------------------------------
// van der Corput sequence generator, base = 2, 16-bit fractional output.
//
// The van der Corput sequence (base 2) produces low-discrepancy points in
// [0, 1).  For a positive integer index n, the value is obtained by
// interpreting the binary representation of n reversed as a fractional number:
//
//   VdC(n) = bit_reverse(n) >> (W - floor(log2(n)) - 1)
//
// With a fixed 16-bit output width we simply reverse the 16 LSBs of the
// internal counter and treat the result as a U(0.16) fixed-point fraction.
//
//                  n (dec) | binary  | reversed | VdC (float) | vdc_out
//                 ---------+---------+----------+-------------+--------
//                     1    | 0001    | 1000     | 0.5         | 0x8000
//                     2    | 0010    | 0100     | 0.25        | 0x4000
//                     3    | 0011    | 1100     | 0.75        | 0xC000
//                     4    | 0100    | 0010     | 0.125       | 0x2000
//                     5    | 0101    | 1010     | 0.625       | 0xA000
//                     ...   | ...     | ...      | ...         | ...
//
// Ports:
//   clk     - Clock (rising-edge active)
//   rst_n   - Asynchronous reset, active low (resets counter to 0)
//   en      - Enable: when asserted the counter advances on the next clock
//   vdc_out - 16-bit fixed-point output (UQ0.16 format, range ≈[0, 1))
//   valid   - Asserted when vdc_out holds a valid sequence value
// -----------------------------------------------------------------------------

module vdc_16 (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       en,
    output wire [15:0] vdc_out,
    output reg        valid
);

    // ------------------------------------------------------------------
    // Internal counter (16 bits — covers the full non-repeating period)
    // ------------------------------------------------------------------
    reg [15:0] cnt;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt    <= 16'd0;
            valid  <= 1'b0;
        end else if (en) begin
            cnt    <= cnt + 16'd1;
            valid  <= 1'b1;
        end else begin
            valid  <= 1'b0;
        end
    end

    // ------------------------------------------------------------------
    // Bit-reversal — the core of VdC base-2
    // ------------------------------------------------------------------
    // Reverse every counter bit so that bit i of cnt maps to bit (15-i)
    // of vdc_out.  This is pure combinational logic — zero area in an
    // FPGA (simple wire permutation) and minimal in ASIC.
    // ------------------------------------------------------------------
    assign vdc_out = {
        cnt[ 0], cnt[ 1], cnt[ 2], cnt[ 3],
        cnt[ 4], cnt[ 5], cnt[ 6], cnt[ 7],
        cnt[ 8], cnt[ 9], cnt[10], cnt[11],
        cnt[12], cnt[13], cnt[14], cnt[15]
    };

endmodule
