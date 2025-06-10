`include "interface.sv"

module JpegCoder #(
  parameter WIDTH = 1280,
  parameter HEIGHT = 720,
  parameter DATA_WIDTH = 10,
  parameter ROW = 3
) (
  input logic pclk, clk, rst_n,
  input dataPort_t in,
  output huffman_pkg::HuffmanBus_t out
);
  import huffman_pkg::HuffmanBus_t;

(* MARK_DEBUG="true" *)  dctPort_t rgb[ROW];
  PingpongBuf #(WIDTH, HEIGHT) pingpong (pclk, clk, rst_n, in, rgb);
  dctPort_t ycbcr[ROW];
  RGB2YCbCr #(DATA_WIDTH) rgb2ycbcr (clk, rst_n, rgb, ycbcr);
  dctPort_t y[ROW];
  Dct #(DATA_WIDTH, ROW) dct (clk, rst_n, ycbcr, y);
  HuffmanBus_t coder2streamGenator[ROW];
  generate
    genvar i;
    for(i=0; i<ROW; i++) begin: colorChannel
      codePort_t quantizer2code;
      Zigzag #(DATA_WIDTH) zigzag (
        clk, rst_n,
        y[i], 
        quantizer2code
      );
      EntropyCoder #(DATA_WIDTH, i) coder (
        clk, rst_n,
        quantizer2code,
        coder2streamGenator[i]
      );
    end
  endgenerate

  // assign out = coder2streamGenator[2];
  compressStreamGenator #(ROW) compressStreamGenator (
    clk, rst_n,
    coder2streamGenator,
    out
  );

endmodule
