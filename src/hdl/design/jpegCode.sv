`include "interface.sv"

module JpegCoder #(
    parameter DATA_WIDTH = 10,
    parameter ROW = 3
) (
    input logic clk,
    input logic rst_n,
    input dctPort_t in[ROW],
    output huffman_pkg::HuffmanBus_t out
);
import huffman_pkg::HuffmanBus_t;
dctPort_t color[ROW];
RGB2YCbCr #(DATA_WIDTH) rgb2ycbcr (clk, rst_n, in, color);
dctPort_t y[ROW];
Dct #(DATA_WIDTH, ROW) dct (clk, rst_n, color, y);
HuffmanBus_t coder2streamGenator[ROW];
generate
  genvar i;
  for(i=0; i<ROW; i++) begin: colorChannel
    codePort_t quantizerOut;
    Zigzag #(DATA_WIDTH) zigzag (
      clk, rst_n,
      y[i], 
      quantizerOut
    );
    codePort_t quantizer2code;
    EntropyCoder #(DATA_WIDTH) coder (
      clk, rst_n,
      quantizerOut,
      coder2streamGenator[i]
    );
  end
  compressStreamGenator #(ROW) compressStreamGenator (
    clk, rst_n,
    coder2streamGenator, out
  );
endgenerate

endmodule
