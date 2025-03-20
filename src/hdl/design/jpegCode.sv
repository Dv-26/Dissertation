`include "interface.sv"
module JpegCode #(
    parameter DATA_WIDTH = 10,
    parameter ROW = 3
) (
    input logic clk,
    input logic rst_n,
    input dctPort_t in[ROW],
    output logic [3:0] zeroNub[ROW]
);

dctPort_t color[ROW];
RGB2YCbCr #(DATA_WIDTH) rgb2ycbcr (clk, rst_n, in, color);
dctPort_t y[ROW];
Dct #(DATA_WIDTH, ROW) dct (clk, rst_n, color, y);
generate
  genvar i;
  for(i=0; i<ROW; i++) begin: colorChannel
    ramWr_if #(DATA_WIDTH, 64) zigzag2quantizer (clk);
    dctPort_t quantizerOut;
    logic zigzagDone;
    Zigzag #(DATA_WIDTH) zigzag (rst_n, y[i], zigzag2quantizer, zigzagDone);
    Quantizer #(DATA_WIDTH, i) quantizer (zigzag2quantizer, quantizerOut);

    codePort_t quantizer2code;
    logic [DATA_WIDTH-2:0] vli;
    logic isDC, valid;
    EntropyCoder #(DATA_WIDTH) coder (
      clk, rst_n,
      quantizer2code,
      vli, zeroNub[i], isDC, valid
    );
    assign quantizer2code.data =  quantizerOut.data;
    assign quantizer2code.valid =  quantizerOut.valid;
    assign quantizer2code.done =  zigzagDone;
  end
endgenerate

endmodule
