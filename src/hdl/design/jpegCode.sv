`include "interface.sv"
module JpegCode #(
    parameter DATA_WIDTH = 10,
    parameter ROW = 3
) (
    input logic clk,
    input logic rst_n,
    input dctPort_t in[ROW],
    output dctPort_t out[ROW]
);

dctPort_t y[ROW];
Dct #(DATA_WIDTH, ROW) dct (clk, rst_n, in, y);
generate
  genvar i;
  for(i=0; i<ROW; i++) begin: colorChannel
    ram_if #(DATA_WIDTH, 64) zigzag2quantizer ();
    Zigzag #(DATA_WIDTH) zigzag (clk, rst_n, y[i], zigzag2quantizer);
    Quantizer #(DATA_WIDTH, i) quantizer (zigzag2quantizer, out[i]);
  end
endgenerate

endmodule
