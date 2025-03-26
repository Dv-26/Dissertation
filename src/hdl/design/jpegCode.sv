`include "interface.sv"
`include "entropyCoder.svh"

module JpegCode #(
    parameter DATA_WIDTH = 10,
    parameter ROW = 3
) (
    input logic clk,
    input logic rst_n,
    input dctPort_t in[ROW],
    output [$bits(tempCode_t)-1:0] out[ROW]
);

dctPort_t color[ROW];
RGB2YCbCr #(DATA_WIDTH) rgb2ycbcr (clk, rst_n, in, color);
dctPort_t y[ROW];
Dct #(DATA_WIDTH, ROW) dct (clk, rst_n, color, y);
generate
  genvar i;
  for(i=0; i<ROW; i++) begin: colorChannel
    ramWr_if #(DATA_WIDTH, 64) zigzag2quantizer (clk);
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
      out[i]
    );
  end
endgenerate

endmodule
