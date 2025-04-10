
module DCHuffmanMap 
import huffman_pkg::*;
#(
  parameter CHROMA = 0 //0:亮度 1:色度
) (
  input logic clk,
  input huffman_pkg::tempCode_t tempCode,
  output huffman_pkg::Huffman_t huffman
);
  
  localparam CODE_W = CHROMA == 0 ? 9 : 11;
  localparam SIZE_W = 4;

  always_ff @(posedge clk) begin
    if(tempCode.valid & tempCode.data.isDC) begin
      // huffman.size[$bits(huffman.size)-1 : SIZE_W] <= '0;
      // huffman.code[$bits(huffman.code)-1 : CODE_W] <= '0;
      {huffman.size[SIZE_W-1:0], huffman.code[CODE_W-1:0]} <= array[tempCode.data.size];
    end
  end

  struct packed {
    logic [SIZE_W-1:0] size;
    logic [CODE_W-1:0] code;
  } array[12];
  initial begin
    if(CHROMA==1) begin
      array[4'h0] = {4'h2, 9'b000000000};
      array[4'h1] = {4'h3, 9'b000000010};
      array[4'h2] = {4'h3, 9'b000000011};
      array[4'h3] = {4'h3, 9'b000000100};
      array[4'h4] = {4'h3, 9'b000000101};
      array[4'h5] = {4'h3, 9'b000000110};
      array[4'h6] = {4'h4, 9'b000001110};
      array[4'h7] = {4'h5, 9'b000011110};
      array[4'h8] = {4'h6, 9'b000111110};
      array[4'h9] = {4'h7, 9'b001111110};
      array[4'ha] = {4'h9, 9'b011111110};
      array[4'hb] = {4'h9, 9'b111111110};
    end else begin
      array[4'h0] = {4'h2, 11'b00000000000};
      array[4'h1] = {4'h2, 11'b00000000001};
      array[4'h2] = {4'h2, 11'b00000000010};
      array[4'h3] = {4'h3, 11'b00000000110};
      array[4'h4] = {4'h4, 11'b00000001110};
      array[4'h5] = {4'h5, 11'b00000011110};
      array[4'h6] = {4'h6, 11'b00000111110};
      array[4'h7] = {4'h7, 11'b00001111110};
      array[4'h8] = {4'h8, 11'b00011111110};
      array[4'h9] = {4'h9, 11'b00111111110};
      array[4'ha] = {4'ha, 11'b01111111110};
      array[4'hb] = {4'hb, 11'b11111111110};
    end
  end
  
endmodule


// module ACHuffmanMap#parameter CHROMA = 1 clk, tempCode, huffman;
//   import huffman_pkg;
//   localparam CODE_W = 16;
//   localparam SIZE_W = $clog2CODE_W + 1;
//
//   input logic clk;
//   input logic tempCode_t tempCode;
//   output Huffman_t huffman;
//
//   logic [CODE_W+SIZE_W-1:0] array [162];
//   always_ff @posedge clk begin
//     iftempCode.valid & !tempCode.isDC begin
//       huffman.size[$bitshuffman.size-1 : SIZE_W] <= '0;
//       huffman.code[$bitshuffman.code-1 : CODE_W] <= '0;
//       {
//         huffman.size[SIZE_W-1:0],
//         huffman.code[CODE_W-1:0]
//       } <= array[
//         tempCode.data.run,
//         tempCode.data.size
//       ];
//     end
//   end
//
//   initial begin
//     ifCHROMA == 1 begin
//       array[{4'h0, 4'h0}] = {SIZE_W'(d4), CODE_W'(b0000000000001010)};
//       array[{4'h0, 4'h1}] = {SIZE_W'(d2), CODE_W'(b0000000000000000)};
//       array[{4'h0, 4'h2}] = {SIZE_W'(d2), CODE_W'(b0000000000000001)};
//       array[{4'h0, 4'h3}] = {SIZE_W'd3, CODE_W'b0000000000000100};
//       array[{4'h0, 4'h4}] = {SIZE_W'd4, CODE_W'b0000000000001011};
//       array[{4'h0, 4'h5}] = {SIZE_W'd5, CODE_W'b0000000000011010};
//       array[{4'h0, 4'h6}] = {SIZE_W'd7, CODE_W'b0000000001111000};
//       array[{4'h0, 4'h7}] = {SIZE_W'd8, CODE_W'b0000000011111000};
//       array[{4'h0, 4'h8}] = {SIZE_W'd10, CODE_W'b0000001111110110};
//       array[{4'h0, 4'h9}] = {SIZE_W'd16, CODE_W'b1111111110000010};
//       array[{4'h0, 4'hA}] = {SIZE_W'd16, CODE_W'b1111111110000011};
//       array[{4'h1, 4'h1}] = {SIZE_W'd4, CODE_W'b0000000000001100};
//       array[{4'h1, 4'h2}] = {SIZE_W'd5, CODE_W'b0000000000011011};
//       array[{4'h1, 4'h3}] = {SIZE_W'd7, CODE_W'b0000000001111001};
//       array[{4'h1, 4'h4}] = {SIZE_W'd9, CODE_W'b0000000111110110};
//       array[{4'h1, 4'h5}] = {SIZE_W'd11, CODE_W'b0000011111110110};
//       array[{4'h1, 4'h6}] = {SIZE_W'd16, CODE_W'b1111111110000100};
//       array[{4'h1, 4'h7}] = {SIZE_W'd16, CODE_W'b1111111110000101};
//       array[{4'h1, 4'h8}] = {SIZE_W'd16, CODE_W'b1111111110000110};
//       array[{4'h1, 4'h9}] = {SIZE_W'd16, CODE_W'b1111111110000111};
//       array[{4'h1, 4'hA}] = {SIZE_W'd16, CODE_W'b1111111110001000};
//       array[{4'h2, 4'h1}] = {SIZE_W'd5, CODE_W'b0000000000011100};
//       array[{4'h2, 4'h2}] = {SIZE_W'd8, CODE_W'b0000000011111001};
//       array[{4'h2, 4'h3}] = {SIZE_W'd10, CODE_W'b0000001111110111};
//       array[{4'h2, 4'h4}] = {SIZE_W'd12, CODE_W'b0000111111110100};
//       array[{4'h2, 4'h5}] = {SIZE_W'd16, CODE_W'b1111111110001001};
//       array[{4'h2, 4'h6}] = {SIZE_W'd16, CODE_W'b1111111110001010};
//       array[{4'h2, 4'h7}] = {SIZE_W'd16, CODE_W'b1111111110001011};
//       array[{4'h2, 4'h8}] = {SIZE_W'd16, CODE_W'b1111111110001100};
//       array[{4'h2, 4'h9}] = {SIZE_W'd16, CODE_W'b1111111110001101};
//       array[{4'h2, 4'hA}] = {SIZE_W'd16, CODE_W'b1111111110001110};
//       array[{4'h3, 4'h1}] = {SIZE_W'd6, CODE_W'b0000000000111010};
//       array[{4'h3, 4'h2}] = {SIZE_W'd9, CODE_W'b0000000111110111};
//       array[{4'h3, 4'h3}] = {SIZE_W'd12, CODE_W'b0000111111110101};
//       array[{4'h3, 4'h4}] = {SIZE_W'd16, CODE_W'b1111111110001111};
//       array[{4'h3, 4'h5}] = {SIZE_W'd16, CODE_W'b1111111110010000};
//       array[{4'h3, 4'h6}] = {SIZE_W'd16, CODE_W'b1111111110010001};
//       array[{4'h3, 4'h7}] = {SIZE_W'd16, CODE_W'b1111111110010010};
//       array[{4'h3, 4'h8}] = {SIZE_W'd16, CODE_W'b1111111110010011};
//       array[{4'h3, 4'h9}] = {SIZE_W'd16, CODE_W'b1111111110010100};
//       array[{4'h3, 4'hA}] = {SIZE_W'd16, CODE_W'b1111111110010101};
//       array[{4'h4, 4'h1}] = {SIZE_W'd6, CODE_W'b0000000000111011};
//       array[{4'h4, 4'h2}] = {SIZE_W'd10, CODE_W'b0000001111111000};
//       array[{4'h4, 4'h3}] = {SIZE_W'd16, CODE_W'b1111111110010110};
//       array[{4'h4, 4'h4}] = {SIZE_W'd16, CODE_W'b1111111110010111};
//       array[{4'h4, 4'h5}] = {SIZE_W'd16, CODE_W'b1111111110011000};
//       array[{4'h4, 4'h6}] = {SIZE_W'd16, CODE_W'b1111111110011001};
//       array[{4'h4, 4'h7}] = {SIZE_W'd16, CODE_W'b1111111110011010};
//       array[{4'h4, 4'h8}] = {SIZE_W'd16, CODE_W'b1111111110011011};
//       array[{4'h4, 4'h9}] = {SIZE_W'd16, CODE_W'b1111111110011100};
//       array[{4'h4, 4'hA}] = {SIZE_W'd16, CODE_W'b1111111110011101};
//       array[{4'h5, 4'h1}] = {SIZE_W'd7, CODE_W'b0000000001111010};
//       array[{4'h5, 4'h2}] = {SIZE_W'd11, CODE_W'b0000011111110111};
//       array[{4'h5, 4'h3}] = {SIZE_W'd16, CODE_W'b1111111110011110};
//       array[{4'h5, 4'h4}] = {SIZE_W'd16, CODE_W'b1111111110011111};
//       array[{4'h5, 4'h5}] = {SIZE_W'd16, CODE_W'b1111111110100000};
//       array[{4'h5, 4'h6}] = {SIZE_W'd16, CODE_W'b1111111110100001};
//       array[{4'h5, 4'h7}] = {SIZE_W'd16, CODE_W'b1111111110100010};
//       array[{4'h5, 4'h8}] = {SIZE_W'd16, CODE_W'b1111111110100011};
//       array[{4'h5, 4'h9}] = {SIZE_W'd16, CODE_W'b1111111110100100};
//       array[{4'h5, 4'hA}] = {SIZE_W'd16, CODE_W'b1111111110100101};
//       array[{4'h6, 4'h1}] = {SIZE_W'd7, CODE_W'b0000000001111011};
//       array[{4'h6, 4'h2}] = {SIZE_W'd12, CODE_W'b0000111111110110};
//       array[{4'h6, 4'h3}] = {SIZE_W'd16, CODE_W'b1111111110100110};
//       array[{4'h6, 4'h4}] = {SIZE_W'd16, CODE_W'b1111111110100111};
//       array[{4'h6, 4'h5}] = {SIZE_W'd16, CODE_W'b1111111110101000};
//       array[{4'h6, 4'h6}] = {SIZE_W'd16, CODE_W'b1111111110101001};
//       array[{4'h6, 4'h7}] = {SIZE_W'd16, CODE_W'b1111111110101010};
//       array[{4'h6, 4'h8}] = {SIZE_W'd16, CODE_W'b1111111110101011};
//       array[{4'h6, 4'h9}] = {SIZE_W'd16, CODE_W'b1111111110101100};
//       array[{4'h6, 4'hA}] = {SIZE_W'd16, CODE_W'b1111111110101101};
//       array[{4'h7, 4'h1}] = {SIZE_W'd8, CODE_W'b0000000011111010};
//       array[{4'h7, 4'h2}] = {SIZE_W'd12, CODE_W'b0000111111110111};
//       array[{4'h7, 4'h3}] = {SIZE_W'd16, CODE_W'b1111111110101110};
//       array[{4'h7, 4'h4}] = {SIZE_W'd16, CODE_W'b1111111110101111};
//       array[{4'h7, 4'h5}] = {SIZE_W'd16, CODE_W'b1111111110110000};
//       array[{4'h7, 4'h6}] = {SIZE_W'd16, CODE_W'b1111111110110001};
//       array[{4'h7, 4'h7}] = {SIZE_W'd16, CODE_W'b1111111110110010};
//       array[{4'h7, 4'h8}] = {SIZE_W'd16, CODE_W'b1111111110110011};
//       array[{4'h7, 4'h9}] = {SIZE_W'd16, CODE_W'b1111111110110100};
//       array[{4'h7, 4'hA}] = {SIZE_W'd16, CODE_W'b1111111110110101};
//       array[{4'h8, 4'h1}] = {SIZE_W'd9, CODE_W'b0000000111111000};
//       array[{4'h8, 4'h2}] = {SIZE_W'd15, CODE_W'b0111111111000000};
//       array[{4'h8, 4'h3}] = {SIZE_W'd16, CODE_W'b1111111110110110};
//       array[{4'h8, 4'h4}] = {SIZE_W'd16, CODE_W'b1111111110110111};
//       array[{4'h8, 4'h5}] = {SIZE_W'd16, CODE_W'b1111111110111000};
//       array[{4'h8, 4'h6}] = {SIZE_W'd16, CODE_W'b1111111110111001};
//       array[{4'h8, 4'h7}] = {SIZE_W'd16, CODE_W'b1111111110111010};
//       array[{4'h8, 4'h8}] = {SIZE_W'd16, CODE_W'b1111111110111011};
//       array[{4'h8, 4'h9}] = {SIZE_W'd16, CODE_W'b1111111110111100};
//       array[{4'h8, 4'hA}] = {SIZE_W'd16, CODE_W'b1111111110111101};
//       array[{4'h9, 4'h1}] = {SIZE_W'd9, CODE_W'b0000000111111001};
//       array[{4'h9, 4'h2}] = {SIZE_W'd16, CODE_W'b1111111110111110};
//       array[{4'h9, 4'h3}] = {SIZE_W'd16, CODE_W'b1111111110111111};
//       array[{4'h9, 4'h4}] = {SIZE_W'd16, CODE_W'b1111111111000000};
//       array[{4'h9, 4'h5}] = {SIZE_W'd16, CODE_W'b1111111111000001};
//       array[{4'h9, 4'h6}] = {SIZE_W'd16, CODE_W'b1111111111000010};
//       array[{4'h9, 4'h7}] = {SIZE_W'd16, CODE_W'b1111111111000011};
//       array[{4'h9, 4'h8}] = {SIZE_W'd16, CODE_W'b1111111111000100};
//       array[{4'h9, 4'h9}] = {SIZE_W'd16, CODE_W'b1111111111000101};
//       array[{4'h9, 4'hA}] = {SIZE_W'd16, CODE_W'b1111111111000110};
//       array[{4'hA, 4'h1}] = {SIZE_W'd9, CODE_W'b0000000111111010};
//       array[{4'hA, 4'h2}] = {SIZE_W'd16, CODE_W'b1111111111000111};
//       array[{4'hA, 4'h3}] = {SIZE_W'd16, CODE_W'b1111111111001000};
//       array[{4'hA, 4'h4}] = {SIZE_W'd16, CODE_W'b1111111111001001};
//       array[{4'hA, 4'h5}] = {SIZE_W'd16, CODE_W'b1111111111001010};
//       array[{4'hA, 4'h6}] = {SIZE_W'd16, CODE_W'b1111111111001011};
//       array[{4'hA, 4'h7}] = {SIZE_W'd16, CODE_W'b1111111111001100};
//       array[{4'hA, 4'h8}] = {SIZE_W'd16, CODE_W'b1111111111001101};
//       array[{4'hA, 4'h9}] = {SIZE_W'd16, CODE_W'b1111111111001110};
//       array[{4'hA, 4'hA}] = {SIZE_W'd16, CODE_W'b1111111111001111};
//       array[{4'hB, 4'h1}] = {SIZE_W'd10, CODE_W'b0000001111111001};
//       array[{4'hB, 4'h2}] = {SIZE_W'd16, CODE_W'b1111111111010000};
//       array[{4'hB, 4'h3}] = {SIZE_W'd16, CODE_W'b1111111111010001};
//       array[{4'hB, 4'h4}] = {SIZE_W'd16, CODE_W'b1111111111010010};
//       array[{4'hB, 4'h5}] = {SIZE_W'd16, CODE_W'b1111111111010011};
//       array[{4'hB, 4'h6}] = {SIZE_W'd16, CODE_W'b1111111111010100};
//       array[{4'hB, 4'h7}] = {SIZE_W'd16, CODE_W'b1111111111010101};
//       array[{4'hB, 4'h8}] = {SIZE_W'd16, CODE_W'b1111111111010110};
//       array[{4'hB, 4'h9}] = {SIZE_W'd16, CODE_W'b1111111111010111};
//       array[{4'hB, 4'hA}] = {SIZE_W'd16, CODE_W'b1111111111011000};
//       array[{4'hC, 4'h1}] = {SIZE_W'd10, CODE_W'b0000001111111010};
//       array[{4'hC, 4'h2}] = {SIZE_W'd16, CODE_W'b1111111111011001};
//       array[{4'hC, 4'h3}] = {SIZE_W'd16, CODE_W'b1111111111011010};
//       array[{4'hC, 4'h4}] = {SIZE_W'd16, CODE_W'b1111111111011011};
//       array[{4'hC, 4'h5}] = {SIZE_W'd16, CODE_W'b1111111111011100};
//       array[{4'hC, 4'h6}] = {SIZE_W'd16, CODE_W'b1111111111011101};
//       array[{4'hC, 4'h7}] = {SIZE_W'd16, CODE_W'b1111111111011110};
//       array[{4'hC, 4'h8}] = {SIZE_W'd16, CODE_W'b1111111111011111};
//       array[{4'hC, 4'h9}] = {SIZE_W'd16, CODE_W'b1111111111100000};
//       array[{4'hC, 4'hA}] = {SIZE_W'd16, CODE_W'b1111111111100001};
//       array[{4'hD, 4'h1}] = {SIZE_W'd11, CODE_W'b0000011111111000};
//       array[{4'hD, 4'h2}] = {SIZE_W'd16, CODE_W'b1111111111100010};
//       array[{4'hD, 4'h3}] = {SIZE_W'd16, CODE_W'b1111111111100011};
//       array[{4'hD, 4'h4}] = {SIZE_W'd16, CODE_W'b1111111111100100};
//       array[{4'hD, 4'h5}] = {SIZE_W'd16, CODE_W'b1111111111100101};
//       array[{4'hD, 4'h6}] = {SIZE_W'd16, CODE_W'b1111111111100110};
//       array[{4'hD, 4'h7}] = {SIZE_W'd16, CODE_W'b1111111111100111};
//       array[{4'hD, 4'h8}] = {SIZE_W'd16, CODE_W'b1111111111101000};
//       array[{4'hD, 4'h9}] = {SIZE_W'd16, CODE_W'b1111111111101001};
//       array[{4'hD, 4'hA}] = {SIZE_W'd16, CODE_W'b1111111111101010};
//       array[{4'hE, 4'h1}] = {SIZE_W'd16, CODE_W'b1111111111101011};
//       array[{4'hE, 4'h2}] = {SIZE_W'd16, CODE_W'b1111111111101100};
//       array[{4'hE, 4'h3}] = {SIZE_W'd16, CODE_W'b1111111111101101};
//       array[{4'hE, 4'h4}] = {SIZE_W'd16, CODE_W'b1111111111101110};
//       array[{4'hE, 4'h5}] = {SIZE_W'd16, CODE_W'b1111111111101111};
//       array[{4'hE, 4'h6}] = {SIZE_W'd16, CODE_W'b1111111111110000};
//       array[{4'hE, 4'h7}] = {SIZE_W'd16, CODE_W'b1111111111110001};
//       array[{4'hE, 4'h8}] = {SIZE_W'd16, CODE_W'b1111111111110010};
//       array[{4'hE, 4'h9}] = {SIZE_W'd16, CODE_W'b1111111111110011};
//       array[{4'hE, 4'hA}] = {SIZE_W'd16, CODE_W'b1111111111110100};
//       array[{4'hF, 4'h0}] = {SIZE_W'd11, CODE_W'b0000011111111001};
//       array[{4'hF, 4'h1}] = {SIZE_W'd16, CODE_W'b1111111111110101};
//       array[{4'hF, 4'h2}] = {SIZE_W'd16, CODE_W'b1111111111110110};
//       array[{4'hF, 4'h3}] = {SIZE_W'd16, CODE_W'b1111111111110111};
//       array[{4'hF, 4'h4}] = {SIZE_W'd16, CODE_W'b1111111111111000};
//       array[{4'hF, 4'h5}] = {SIZE_W'd16, CODE_W'b1111111111111001};
//       array[{4'hF, 4'h6}] = {SIZE_W'd16, CODE_W'b1111111111111010};
//       array[{4'hF, 4'h7}] = {SIZE_W'd16, CODE_W'b1111111111111011};
//       array[{4'hF, 4'h8}] = {SIZE_W'd16, CODE_W'b1111111111111100};
//       array[{4'hF, 4'h9}] = {SIZE_W'd16, CODE_W'b1111111111111101};
//       array[{4'hF, 4'hA}] = {SIZE_W'd16, CODE_W'b1111111111111110};
//     end else begin
//       array[{4'h0, 4'h0}] = {SIZE_W'd2, CODE_W'b0000000000000000};
//       array[{4'h0, 4'h1}] = {SIZE_W'd2, CODE_W'b0000000000000001};
//       array[{4'h0, 4'h2}] = {SIZE_W'd3, CODE_W'b0000000000000100};
//       array[{4'h0, 4'h3}] = {SIZE_W'd4, CODE_W'b0000000000001010};
//       array[{4'h0, 4'h4}] = {SIZE_W'd5, CODE_W'b0000000000011000};
//       array[{4'h0, 4'h5}] = {SIZE_W'd5, CODE_W'b0000000000011001};
//       array[{4'h0, 4'h6}] = {SIZE_W'd6, CODE_W'b0000000000111000};
//       array[{4'h0, 4'h7}] = {SIZE_W'd7, CODE_W'b0000000001111000};
//       array[{4'h0, 4'h8}] = {SIZE_W'd9, CODE_W'b0000000111110100};
//       array[{4'h0, 4'h9}] = {SIZE_W'd10, CODE_W'b0000001111110110};
//       array[{4'h0, 4'hA}] = {SIZE_W'd12, CODE_W'b0000111111110100};
//       array[{4'h1, 4'h1}] = {SIZE_W'd4, CODE_W'b0000000000001011};
//       array[{4'h1, 4'h2}] = {SIZE_W'd6, CODE_W'b0000000000111001};
//       array[{4'h1, 4'h3}] = {SIZE_W'd8, CODE_W'b0000000011110110};
//       array[{4'h1, 4'h4}] = {SIZE_W'd9, CODE_W'b0000000111110101};
//       array[{4'h1, 4'h5}] = {SIZE_W'd11, CODE_W'b0000011111110110};
//       array[{4'h1, 4'h6}] = {SIZE_W'd12, CODE_W'b0000111111110101};
//       array[{4'h1, 4'h7}] = {SIZE_W'd16, CODE_W'b1111111110001000};
//       array[{4'h1, 4'h8}] = {SIZE_W'd16, CODE_W'b1111111110001001};
//       array[{4'h1, 4'h9}] = {SIZE_W'd16, CODE_W'b1111111110001010};
//       array[{4'h1, 4'hA}] = {SIZE_W'd16, CODE_W'b1111111110001011};
//       array[{4'h2, 4'h1}] = {SIZE_W'd5, CODE_W'b0000000000011010};
//       array[{4'h2, 4'h2}] = {SIZE_W'd8, CODE_W'b0000000011110111};
//       array[{4'h2, 4'h3}] = {SIZE_W'd10, CODE_W'b0000001111110111};
//       array[{4'h2, 4'h4}] = {SIZE_W'd12, CODE_W'b0000111111110110};
//       array[{4'h2, 4'h5}] = {SIZE_W'd15, CODE_W'b0111111111000010};
//       array[{4'h2, 4'h6}] = {SIZE_W'd16, CODE_W'b1111111110001100};
//       array[{4'h2, 4'h7}] = {SIZE_W'd16, CODE_W'b1111111110001101};
//       array[{4'h2, 4'h8}] = {SIZE_W'd16, CODE_W'b1111111110001110};
//       array[{4'h2, 4'h9}] = {SIZE_W'd16, CODE_W'b1111111110001111};
//       array[{4'h2, 4'hA}] = {SIZE_W'd16, CODE_W'b1111111110010000};
//       array[{4'h3, 4'h1}] = {SIZE_W'd5, CODE_W'b0000000000011011};
//       array[{4'h3, 4'h2}] = {SIZE_W'd8, CODE_W'b0000000011111000};
//       array[{4'h3, 4'h3}] = {SIZE_W'd10, CODE_W'b0000001111111000};
//       array[{4'h3, 4'h4}] = {SIZE_W'd12, CODE_W'b0000111111110111};
//       array[{4'h3, 4'h5}] = {SIZE_W'd16, CODE_W'b1111111110010001};
//       array[{4'h3, 4'h6}] = {SIZE_W'd16, CODE_W'b1111111110010010};
//       array[{4'h3, 4'h7}] = {SIZE_W'd16, CODE_W'b1111111110010011};
//       array[{4'h3, 4'h8}] = {SIZE_W'd16, CODE_W'b1111111110010100};
//       array[{4'h3, 4'h9}] = {SIZE_W'd16, CODE_W'b1111111110010101};
//       array[{4'h3, 4'hA}] = {SIZE_W'd16, CODE_W'b1111111110010110};
//       array[{4'h4, 4'h1}] = {SIZE_W'd6, CODE_W'b0000000000111010};
//       array[{4'h4, 4'h2}] = {SIZE_W'd9, CODE_W'b0000000111110110};
//       array[{4'h4, 4'h3}] = {SIZE_W'd16, CODE_W'b1111111110010111};
//       array[{4'h4, 4'h4}] = {SIZE_W'd16, CODE_W'b1111111110011000};
//       array[{4'h4, 4'h5}] = {SIZE_W'd16, CODE_W'b1111111110011001};
//       array[{4'h4, 4'h6}] = {SIZE_W'd16, CODE_W'b1111111110011010};
//       array[{4'h4, 4'h7}] = {SIZE_W'd16, CODE_W'b1111111110011011};
//       array[{4'h4, 4'h8}] = {SIZE_W'd16, CODE_W'b1111111110011100};
//       array[{4'h4, 4'h9}] = {SIZE_W'd16, CODE_W'b1111111110011101};
//       array[{4'h4, 4'hA}] = {SIZE_W'd16, CODE_W'b1111111110011110};
//       array[{4'h5, 4'h1}] = {SIZE_W'd6, CODE_W'b0000000000111011};
//       array[{4'h5, 4'h2}] = {SIZE_W'd10, CODE_W'b0000001111111001};
//       array[{4'h5, 4'h3}] = {SIZE_W'd16, CODE_W'b1111111110011111};
//       array[{4'h5, 4'h4}] = {SIZE_W'd16, CODE_W'b1111111110100000};
//       array[{4'h5, 4'h5}] = {SIZE_W'd16, CODE_W'b1111111110100001};
//       array[{4'h5, 4'h6}] = {SIZE_W'd16, CODE_W'b1111111110100010};
//       array[{4'h5, 4'h7}] = {SIZE_W'd16, CODE_W'b1111111110100011};
//       array[{4'h5, 4'h8}] = {SIZE_W'd16, CODE_W'b1111111110100100};
//       array[{4'h5, 4'h9}] = {SIZE_W'd16, CODE_W'b1111111110100101};
//       array[{4'h5, 4'hA}] = {SIZE_W'd16, CODE_W'b1111111110100110};
//       array[{4'h6, 4'h1}] = {SIZE_W'd7, CODE_W'b0000000001111001};
//       array[{4'h6, 4'h2}] = {SIZE_W'd11, CODE_W'b0000011111110111};
//       array[{4'h6, 4'h3}] = {SIZE_W'd16, CODE_W'b1111111110100111};
//       array[{4'h6, 4'h4}] = {SIZE_W'd16, CODE_W'b1111111110101000};
//       array[{4'h6, 4'h5}] = {SIZE_W'd16, CODE_W'b1111111110101001};
//       array[{4'h6, 4'h6}] = {SIZE_W'd16, CODE_W'b1111111110101010};
//       array[{4'h6, 4'h7}] = {SIZE_W'd16, CODE_W'b1111111110101011};
//       array[{4'h6, 4'h8}] = {SIZE_W'd16, CODE_W'b1111111110101100};
//       array[{4'h6, 4'h9}] = {SIZE_W'd16, CODE_W'b1111111110101101};
//       array[{4'h6, 4'hA}] = {SIZE_W'd16, CODE_W'b1111111110101110};
//       array[{4'h7, 4'h1}] = {SIZE_W'd7, CODE_W'b0000000001111010};
//       array[{4'h7, 4'h2}] = {SIZE_W'd11, CODE_W'b0000011111111000};
//       array[{4'h7, 4'h3}] = {SIZE_W'd16, CODE_W'b1111111110101111};
//       array[{4'h7, 4'h4}] = {SIZE_W'd16, CODE_W'b1111111110110000};
//       array[{4'h7, 4'h5}] = {SIZE_W'd16, CODE_W'b1111111110110001};
//       array[{4'h7, 4'h6}] = {SIZE_W'd16, CODE_W'b1111111110110010};
//       array[{4'h7, 4'h7}] = {SIZE_W'd16, CODE_W'b1111111110110011};
//       array[{4'h7, 4'h8}] = {SIZE_W'd16, CODE_W'b1111111110110100};
//       array[{4'h7, 4'h9}] = {SIZE_W'd16, CODE_W'b1111111110110101};
//       array[{4'h7, 4'hA}] = {SIZE_W'd16, CODE_W'b1111111110110110};
//       array[{4'h8, 4'h1}] = {SIZE_W'd8, CODE_W'b0000000011111001};
//       array[{4'h8, 4'h2}] = {SIZE_W'd16, CODE_W'b1111111110110111};
//       array[{4'h8, 4'h3}] = {SIZE_W'd16, CODE_W'b1111111110111000};
//       array[{4'h8, 4'h4}] = {SIZE_W'd16, CODE_W'b1111111110111001};
//       array[{4'h8, 4'h5}] = {SIZE_W'd16, CODE_W'b1111111110111010};
//       array[{4'h8, 4'h6}] = {SIZE_W'd16, CODE_W'b1111111110111011};
//       array[{4'h8, 4'h7}] = {SIZE_W'd16, CODE_W'b1111111110111100};
//       array[{4'h8, 4'h8}] = {SIZE_W'd16, CODE_W'b1111111110111101};
//       array[{4'h8, 4'h9}] = {SIZE_W'd16, CODE_W'b1111111110111110};
//       array[{4'h8, 4'hA}] = {SIZE_W'd16, CODE_W'b1111111110111111};
//       array[{4'h9, 4'h1}] = {SIZE_W'd9, CODE_W'b0000000111110111};
//       array[{4'h9, 4'h2}] = {SIZE_W'd16, CODE_W'b1111111111000000};
//       array[{4'h9, 4'h3}] = {SIZE_W'd16, CODE_W'b1111111111000001};
//       array[{4'h9, 4'h4}] = {SIZE_W'd16, CODE_W'b1111111111000010};
//       array[{4'h9, 4'h5}] = {SIZE_W'd16, CODE_W'b1111111111000011};
//       array[{4'h9, 4'h6}] = {SIZE_W'd16, CODE_W'b1111111111000100};
//       array[{4'h9, 4'h7}] = {SIZE_W'd16, CODE_W'b1111111111000101};
//       array[{4'h9, 4'h8}] = {SIZE_W'd16, CODE_W'b1111111111000110};
//       array[{4'h9, 4'h9}] = {SIZE_W'd16, CODE_W'b1111111111000111};
//       array[{4'h9, 4'hA}] = {SIZE_W'd16, CODE_W'b1111111111001000};
//       array[{4'hA, 4'h1}] = {SIZE_W'd9, CODE_W'b0000000111111000};
//       array[{4'hA, 4'h2}] = {SIZE_W'd16, CODE_W'b1111111111001001};
//       array[{4'hA, 4'h3}] = {SIZE_W'd16, CODE_W'b1111111111001010};
//       array[{4'hA, 4'h4}] = {SIZE_W'd16, CODE_W'b1111111111001011};
//       array[{4'hA, 4'h5}] = {SIZE_W'd16, CODE_W'b1111111111001100};
//       array[{4'hA, 4'h6}] = {SIZE_W'd16, CODE_W'b1111111111001101};
//       array[{4'hA, 4'h7}] = {SIZE_W'd16, CODE_W'b1111111111001110};
//       array[{4'hA, 4'h8}] = {SIZE_W'd16, CODE_W'b1111111111001111};
//       array[{4'hA, 4'h9}] = {SIZE_W'd16, CODE_W'b1111111111010000};
//       array[{4'hA, 4'hA}] = {SIZE_W'd16, CODE_W'b1111111111010001};
//       array[{4'hB, 4'h1}] = {SIZE_W'd9, CODE_W'b0000000111111001};
//       array[{4'hB, 4'h2}] = {SIZE_W'd16, CODE_W'b1111111111010010};
//       array[{4'hB, 4'h3}] = {SIZE_W'd16, CODE_W'b1111111111010011};
//       array[{4'hB, 4'h4}] = {SIZE_W'd16, CODE_W'b1111111111010100};
//       array[{4'hB, 4'h5}] = {SIZE_W'd16, CODE_W'b1111111111010101};
//       array[{4'hB, 4'h6}] = {SIZE_W'd16, CODE_W'b1111111111010110};
//       array[{4'hB, 4'h7}] = {SIZE_W'd16, CODE_W'b1111111111010111};
//       array[{4'hB, 4'h8}] = {SIZE_W'd16, CODE_W'b1111111111011000};
//       array[{4'hB, 4'h9}] = {SIZE_W'd16, CODE_W'b1111111111011001};
//       array[{4'hB, 4'hA}] = {SIZE_W'd16, CODE_W'b1111111111011010};
//       array[{4'hC, 4'h1}] = {SIZE_W'd9, CODE_W'b0000000111111010};
//       array[{4'hC, 4'h2}] = {SIZE_W'd16, CODE_W'b1111111111011011};
//       array[{4'hC, 4'h3}] = {SIZE_W'd16, CODE_W'b1111111111011100};
//       array[{4'hC, 4'h4}] = {SIZE_W'd16, CODE_W'b1111111111011101};
//       array[{4'hC, 4'h5}] = {SIZE_W'd16, CODE_W'b1111111111011110};
//       array[{4'hC, 4'h6}] = {SIZE_W'd16, CODE_W'b1111111111011111};
//       array[{4'hC, 4'h7}] = {SIZE_W'd16, CODE_W'b1111111111100000};
//       array[{4'hC, 4'h8}] = {SIZE_W'd16, CODE_W'b1111111111100001};
//       array[{4'hC, 4'h9}] = {SIZE_W'd16, CODE_W'b1111111111100010};
//       array[{4'hC, 4'hA}] = {SIZE_W'd16, CODE_W'b1111111111100011};
//       array[{4'hD, 4'h1}] = {SIZE_W'd11, CODE_W'b0000011111111001};
//       array[{4'hD, 4'h2}] = {SIZE_W'd16, CODE_W'b1111111111100100};
//       array[{4'hD, 4'h3}] = {SIZE_W'd16, CODE_W'b1111111111100101};
//       array[{4'hD, 4'h4}] = {SIZE_W'd16, CODE_W'b1111111111100110};
//       array[{4'hD, 4'h5}] = {SIZE_W'd16, CODE_W'b1111111111100111};
//       array[{4'hD, 4'h6}] = {SIZE_W'd16, CODE_W'b1111111111101000};
//       array[{4'hD, 4'h7}] = {SIZE_W'd16, CODE_W'b1111111111101001};
//       array[{4'hD, 4'h8}] = {SIZE_W'd16, CODE_W'b1111111111101010};
//       array[{4'hD, 4'h9}] = {SIZE_W'd16, CODE_W'b1111111111101011};
//       array[{4'hD, 4'hA}] = {SIZE_W'd16, CODE_W'b1111111111101100};
//       array[{4'hE, 4'h1}] = {SIZE_W'd14, CODE_W'b0011111111100000};
//       array[{4'hE, 4'h2}] = {SIZE_W'd16, CODE_W'b1111111111101101};
//       array[{4'hE, 4'h3}] = {SIZE_W'd16, CODE_W'b1111111111101110};
//       array[{4'hE, 4'h4}] = {SIZE_W'd16, CODE_W'b1111111111101111};
//       array[{4'hE, 4'h5}] = {SIZE_W'd16, CODE_W'b1111111111110000};
//       array[{4'hE, 4'h6}] = {SIZE_W'd16, CODE_W'b1111111111110001};
//       array[{4'hE, 4'h7}] = {SIZE_W'd16, CODE_W'b1111111111110010};
//       array[{4'hE, 4'h8}] = {SIZE_W'd16, CODE_W'b1111111111110011};
//       array[{4'hE, 4'h9}] = {SIZE_W'd16, CODE_W'b1111111111110100};
//       array[{4'hE, 4'hA}] = {SIZE_W'd16, CODE_W'b1111111111110101};
//       array[{4'hF, 4'h0}] = {SIZE_W'd10, CODE_W'b0000001111111010};
//       array[{4'hF, 4'h1}] = {SIZE_W'd15, CODE_W'b0111111111000011};
//       array[{4'hF, 4'h2}] = {SIZE_W'd16, CODE_W'b1111111111110110};
//       array[{4'hF, 4'h3}] = {SIZE_W'd16, CODE_W'b1111111111110111};
//       array[{4'hF, 4'h4}] = {SIZE_W'd16, CODE_W'b1111111111111000};
//       array[{4'hF, 4'h5}] = {SIZE_W'd16, CODE_W'b1111111111111001};
//       array[{4'hF, 4'h6}] = {SIZE_W'd16, CODE_W'b1111111111111010};
//       array[{4'hF, 4'h7}] = {SIZE_W'd16, CODE_W'b1111111111111011};
//       array[{4'hF, 4'h8}] = {SIZE_W'd16, CODE_W'b1111111111111100};
//       array[{4'hF, 4'h9}] = {SIZE_W'd16, CODE_W'b1111111111111101};
//       array[{4'hF, 4'hA}] = {SIZE_W'd16, CODE_W'b1111111111111110};
//     end
// end
// endmodule
