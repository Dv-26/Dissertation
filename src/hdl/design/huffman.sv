`include "entropyCoder.svh"

module FixedLengthGen (clk, rst_n, in, out);
  import huffman_pkg::*; 

  input logic clk, rst_n;
  input HuffmanBus_t in;
  output HuffmanBus_t out;

  struct {
    logic [$clog2(CODE_W):0] current, next;
  } shiftCnt, size; 
  logic [CODE_W-1:0] up, low;
  logic overflow;

  always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      size.current <= 0;
      shiftCnt.current <= 0;
    end else begin
      size.current <= size.next;
      shiftCnt.current <= shiftCnt.next;
    end
  end
  always_comb begin
    shiftCnt.next = shiftCnt.current;
    size.next = size.current;
    overflow = 0;
    if(in.valid) begin
      shiftCnt.next += in.data.size;
      overflow = shiftCnt.next >= CODE_W;
      if(overflow)
        shiftCnt.next -= CODE_W;
      if(in.done) begin
        size.next = shiftCnt.next;
        shiftCnt.next = 0;
      end
    end
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      {up, low} <= '0;
    end else if(in.valid) begin
      {up, low} <= {in.data.code, 36'b0} >> shiftCnt.current;
    end
  end

  struct packed{
    logic valid, overflow;
  } inDelay;
  always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      inDelay <= '0;
    end else begin
      inDelay <= {in.valid, overflow};
    end
  end

  logic [CODE_W-1:0] splice;
  struct {logic [CODE_W-1:0] next, current;} spliceReg;
  struct {HuffmanBus_t next, current;} outReg;
  struct {
    enum logic[2:0] {NORMAL, DONE, OVERFLOW} next, current;
  } state;


  always_comb begin
    splice = spliceReg.current | up;
    state.next = state.current;
    outReg.next.data = outReg.current.data;
    spliceReg.next = spliceReg.current;
    outReg.next.valid = 0;
    outReg.next.done = 0;
    case(state.current)
      NORMAL:begin
        if(inDelay.valid) begin
          spliceReg.next = splice;
          if(inDelay.overflow) begin
            spliceReg.next = low;
            outReg.next.data.code = splice;
            outReg.next.data.size = CODE_W;
            outReg.next.valid = 1;
          end
        end

        if(in.valid & in.done)
          state.next = DONE;
      end
      DONE:begin
        spliceReg.next = '0;
        outReg.next.data.code = splice;
        outReg.next.data.size = size.current;
        outReg.next.valid = 1;
        outReg.next.done = 1;
        state.next = NORMAL;
        if(inDelay.overflow) begin
          state.next = OVERFLOW;
          outReg.next.data.size = CODE_W;
          outReg.next.done = 0;
          spliceReg.next = low;
        end
      end
      OVERFLOW:begin
        state.next = NORMAL;
        outReg.next.data.code = spliceReg.current;
        outReg.next.data.size = size.current;
        outReg.next.valid = 1;
        outReg.next.done = 1;
        if(inDelay.valid)
          spliceReg.next = up;
      end
    endcase
  end

  always_ff @(posedge clk)begin
    outReg.current.data <= outReg.next.data;
  end
  always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      outReg.current.valid <= 0;
      outReg.current.done <= 0;
      spliceReg.current <= '0;
      state.current <= NORMAL;
    end else begin
      outReg.current.valid <= outReg.next.valid;
      outReg.current.done <= outReg.next.done;
      spliceReg.current <= spliceReg.next;
      state.current <= state.next;
    end
  end
  assign out = outReg.current;
endmodule

module IndefiniteLengthCodeGen #(parameter CHROMA = 0) (clk, rst_n, tempCode, huffman);
  import huffman_pkg::*; 
  input logic clk, rst_n;
  input tempCode_t tempCode;
  output HuffmanBus_t huffman;

  Huffman_t dcHuffman;
  DCHuffmanMap #(CHROMA) dcHuffmanMap (clk, tempCode, dcHuffman);
  Huffman_t acHuffman;
  ACHuffmanMap #(CHROMA) acHuffmanMap (clk, tempCode, acHuffman);

  tempCode_t tempCodeDelay;
  always_ff @(posedge clk or negedge rst_n)
    tempCodeDelay <= !rst_n ? '0 : tempCode;

  struct packed {
    HuffmanBus_t current;
    HuffmanBus_t next;
  } huffmanFF[2];

  always_comb begin
    huffmanFF[0].next.data = huffmanFF[0].current.data;
    huffmanFF[0].next.valid = tempCode.valid;
    huffmanFF[0].next.done = tempCode.done;
    if(tempCodeDelay.valid)begin
      huffmanFF[0].next.data = tempCodeDelay.data.isDC ? dcHuffman : acHuffman;
      huffmanFF[0].next.data.code <<= tempCodeDelay.data.size;
      huffmanFF[0].next.data.code |= (1 << tempCodeDelay.data.size) - 1;
      huffmanFF[0].next.data.code &=  tempCodeDelay.data.vli;
      huffmanFF[0].next.data.size += tempCodeDelay.data.size;
    end
  end
  always_ff @(posedge clk or negedge rst_n)
    huffmanFF[0].current <= !rst_n ? '0 : huffmanFF[0].next;

  always_comb begin
    huffmanFF[1].next = huffmanFF[0].current;
    huffmanFF[1].next.data.code <<= CODE_W - huffmanFF[0].current.data.size;
  end
  always_ff @(posedge clk or negedge rst_n)
    huffmanFF[1].current <= !rst_n ? '0 : huffmanFF[1].next;

  assign huffman = huffmanFF[1].current;
  
endmodule

module DCHuffmanMap 
#( parameter CHROMA = 0) ( clk, tempCode, huffman);
  import huffman_pkg::*;
  input logic clk;
  input tempCode_t tempCode;
  output Huffman_t huffman;

  localparam ROM_CODE_W = CHROMA == 0 ? 9 : 11;
  localparam ROM_SIZE_W = 5;

  always_ff @(posedge clk) begin
    if(tempCode.valid & tempCode.data.isDC) begin
      {huffman.size[ROM_SIZE_W-1:0], huffman.code[ROM_CODE_W-1:0]} <= array[tempCode.data.size];
    end
  end
  assign huffman.size[$bits(huffman.size)-1 : ROM_SIZE_W] = '0;
  assign huffman.code[$bits(huffman.code)-1 : ROM_CODE_W] = '0;

  struct packed {
    logic [ROM_SIZE_W-1:0] size;
    logic [ROM_CODE_W-1:0] code;
  } array[12];
  initial begin
    if(CHROMA==0) begin
      array[4'h0] = {5'h2, 9'b000000000};
      array[4'h1] = {5'h3, 9'b000000010};
      array[4'h2] = {5'h3, 9'b000000011};
      array[4'h3] = {5'h3, 9'b000000100};
      array[4'h4] = {5'h3, 9'b000000101};
      array[4'h5] = {5'h3, 9'b000000110};
      array[4'h6] = {5'h4, 9'b000001110};
      array[4'h7] = {5'h5, 9'b000011110};
      array[4'h8] = {5'h6, 9'b000111110};
      array[4'h9] = {5'h7, 9'b001111110};
      array[4'ha] = {5'h9, 9'b011111110};
      array[4'hb] = {5'h9, 9'b111111110};
    end else begin
      array[4'h0] = {5'h2, 11'b00000000000};
      array[4'h1] = {5'h2, 11'b00000000001};
      array[4'h2] = {5'h2, 11'b00000000010};
      array[4'h3] = {5'h3, 11'b00000000110};
      array[4'h4] = {5'h4, 11'b00000001110};
      array[4'h5] = {5'h5, 11'b00000011110};
      array[4'h6] = {5'h6, 11'b00000111110};
      array[4'h7] = {5'h7, 11'b00001111110};
      array[4'h8] = {5'h8, 11'b00011111110};
      array[4'h9] = {5'h9, 11'b00111111110};
      array[4'ha] = {5'ha, 11'b01111111110};
      array[4'hb] = {5'hb, 11'b11111111110};
    end
  end

endmodule


module ACHuffmanMap#(parameter CHROMA = 1) (clk, tempCode, huffman);
  import huffman_pkg::*;
  localparam ROM_CODE_W = 16;
  localparam ROM_SIZE_W = 6;

  input logic clk;
  input tempCode_t tempCode;
  output Huffman_t huffman;

  logic [ROM_CODE_W+ROM_SIZE_W-1:0] array [162];
  always_ff @(posedge clk) begin
    if(tempCode.valid & !tempCode.data.isDC) begin
      {
        huffman.size[ROM_SIZE_W-1:0],
        huffman.code[ROM_CODE_W-1:0]
      } <= array[{
        tempCode.data.run,
        tempCode.data.size
      }];
    end
  end
  assign huffman.size[$bits(huffman.size)-1 : ROM_SIZE_W] = '0;
  assign huffman.code[$bits(huffman.code)-1 : ROM_CODE_W] = '0;

  initial begin
    if(CHROMA == 0) begin
      array[{4'h0, 4'h0}] = {6'd4, 16'b0000000000001010};
      array[{4'h0, 4'h1}] = {6'd2, 16'b0000000000000000};
      array[{4'h0, 4'h2}] = {6'd2, 16'b0000000000000001};
      array[{4'h0, 4'h3}] = {6'd3, 16'b0000000000000100};
      array[{4'h0, 4'h4}] = {6'd4, 16'b0000000000001011};
      array[{4'h0, 4'h5}] = {6'd5, 16'b0000000000011010};
      array[{4'h0, 4'h6}] = {6'd7, 16'b0000000001111000};
      array[{4'h0, 4'h7}] = {6'd8, 16'b0000000011111000};
      array[{4'h0, 4'h8}] = {6'd10, 16'b0000001111110110};
      array[{4'h0, 4'h9}] = {6'd16, 16'b1111111110000010};
      array[{4'h0, 4'hA}] = {6'd16, 16'b1111111110000011};
      array[{4'h1, 4'h1}] = {6'd4, 16'b0000000000001100};
      array[{4'h1, 4'h2}] = {6'd5, 16'b0000000000011011};
      array[{4'h1, 4'h3}] = {6'd7, 16'b0000000001111001};
      array[{4'h1, 4'h4}] = {6'd9, 16'b0000000111110110};
      array[{4'h1, 4'h5}] = {6'd11, 16'b0000011111110110};
      array[{4'h1, 4'h6}] = {6'd16, 16'b1111111110000100};
      array[{4'h1, 4'h7}] = {6'd16, 16'b1111111110000101};
      array[{4'h1, 4'h8}] = {6'd16, 16'b1111111110000110};
      array[{4'h1, 4'h9}] = {6'd16, 16'b1111111110000111};
      array[{4'h1, 4'hA}] = {6'd16, 16'b1111111110001000};
      array[{4'h2, 4'h1}] = {6'd5, 16'b0000000000011100};
      array[{4'h2, 4'h2}] = {6'd8, 16'b0000000011111001};
      array[{4'h2, 4'h3}] = {6'd10, 16'b0000001111110111};
      array[{4'h2, 4'h4}] = {6'd12, 16'b0000111111110100};
      array[{4'h2, 4'h5}] = {6'd16, 16'b1111111110001001};
      array[{4'h2, 4'h6}] = {6'd16, 16'b1111111110001010};
      array[{4'h2, 4'h7}] = {6'd16, 16'b1111111110001011};
      array[{4'h2, 4'h8}] = {6'd16, 16'b1111111110001100};
      array[{4'h2, 4'h9}] = {6'd16, 16'b1111111110001101};
      array[{4'h2, 4'hA}] = {6'd16, 16'b1111111110001110};
      array[{4'h3, 4'h1}] = {6'd6, 16'b0000000000111010};
      array[{4'h3, 4'h2}] = {6'd9, 16'b0000000111110111};
      array[{4'h3, 4'h3}] = {6'd12, 16'b0000111111110101};
      array[{4'h3, 4'h4}] = {6'd16, 16'b1111111110001111};
      array[{4'h3, 4'h5}] = {6'd16, 16'b1111111110010000};
      array[{4'h3, 4'h6}] = {6'd16, 16'b1111111110010001};
      array[{4'h3, 4'h7}] = {6'd16, 16'b1111111110010010};
      array[{4'h3, 4'h8}] = {6'd16, 16'b1111111110010011};
      array[{4'h3, 4'h9}] = {6'd16, 16'b1111111110010100};
      array[{4'h3, 4'hA}] = {6'd16, 16'b1111111110010101};
      array[{4'h4, 4'h1}] = {6'd6, 16'b0000000000111011};
      array[{4'h4, 4'h2}] = {6'd10, 16'b0000001111111000};
      array[{4'h4, 4'h3}] = {6'd16, 16'b1111111110010110};
      array[{4'h4, 4'h4}] = {6'd16, 16'b1111111110010111};
      array[{4'h4, 4'h5}] = {6'd16, 16'b1111111110011000};
      array[{4'h4, 4'h6}] = {6'd16, 16'b1111111110011001};
      array[{4'h4, 4'h7}] = {6'd16, 16'b1111111110011010};
      array[{4'h4, 4'h8}] = {6'd16, 16'b1111111110011011};
      array[{4'h4, 4'h9}] = {6'd16, 16'b1111111110011100};
      array[{4'h4, 4'hA}] = {6'd16, 16'b1111111110011101};
      array[{4'h5, 4'h1}] = {6'd7, 16'b0000000001111010};
      array[{4'h5, 4'h2}] = {6'd11, 16'b0000011111110111};
      array[{4'h5, 4'h3}] = {6'd16, 16'b1111111110011110};
      array[{4'h5, 4'h4}] = {6'd16, 16'b1111111110011111};
      array[{4'h5, 4'h5}] = {6'd16, 16'b1111111110100000};
      array[{4'h5, 4'h6}] = {6'd16, 16'b1111111110100001};
      array[{4'h5, 4'h7}] = {6'd16, 16'b1111111110100010};
      array[{4'h5, 4'h8}] = {6'd16, 16'b1111111110100011};
      array[{4'h5, 4'h9}] = {6'd16, 16'b1111111110100100};
      array[{4'h5, 4'hA}] = {6'd16, 16'b1111111110100101};
      array[{4'h6, 4'h1}] = {6'd7, 16'b0000000001111011};
      array[{4'h6, 4'h2}] = {6'd12, 16'b0000111111110110};
      array[{4'h6, 4'h3}] = {6'd16, 16'b1111111110100110};
      array[{4'h6, 4'h4}] = {6'd16, 16'b1111111110100111};
      array[{4'h6, 4'h5}] = {6'd16, 16'b1111111110101000};
      array[{4'h6, 4'h6}] = {6'd16, 16'b1111111110101001};
      array[{4'h6, 4'h7}] = {6'd16, 16'b1111111110101010};
      array[{4'h6, 4'h8}] = {6'd16, 16'b1111111110101011};
      array[{4'h6, 4'h9}] = {6'd16, 16'b1111111110101100};
      array[{4'h6, 4'hA}] = {6'd16, 16'b1111111110101101};
      array[{4'h7, 4'h1}] = {6'd8, 16'b0000000011111010};
      array[{4'h7, 4'h2}] = {6'd12, 16'b0000111111110111};
      array[{4'h7, 4'h3}] = {6'd16, 16'b1111111110101110};
      array[{4'h7, 4'h4}] = {6'd16, 16'b1111111110101111};
      array[{4'h7, 4'h5}] = {6'd16, 16'b1111111110110000};
      array[{4'h7, 4'h6}] = {6'd16, 16'b1111111110110001};
      array[{4'h7, 4'h7}] = {6'd16, 16'b1111111110110010};
      array[{4'h7, 4'h8}] = {6'd16, 16'b1111111110110011};
      array[{4'h7, 4'h9}] = {6'd16, 16'b1111111110110100};
      array[{4'h7, 4'hA}] = {6'd16, 16'b1111111110110101};
      array[{4'h8, 4'h1}] = {6'd9, 16'b0000000111111000};
      array[{4'h8, 4'h2}] = {6'd15, 16'b0111111111000000};
      array[{4'h8, 4'h3}] = {6'd16, 16'b1111111110110110};
      array[{4'h8, 4'h4}] = {6'd16, 16'b1111111110110111};
      array[{4'h8, 4'h5}] = {6'd16, 16'b1111111110111000};
      array[{4'h8, 4'h6}] = {6'd16, 16'b1111111110111001};
      array[{4'h8, 4'h7}] = {6'd16, 16'b1111111110111010};
      array[{4'h8, 4'h8}] = {6'd16, 16'b1111111110111011};
      array[{4'h8, 4'h9}] = {6'd16, 16'b1111111110111100};
      array[{4'h8, 4'hA}] = {6'd16, 16'b1111111110111101};
      array[{4'h9, 4'h1}] = {6'd9, 16'b0000000111111001};
      array[{4'h9, 4'h2}] = {6'd16, 16'b1111111110111110};
      array[{4'h9, 4'h3}] = {6'd16, 16'b1111111110111111};
      array[{4'h9, 4'h4}] = {6'd16, 16'b1111111111000000};
      array[{4'h9, 4'h5}] = {6'd16, 16'b1111111111000001};
      array[{4'h9, 4'h6}] = {6'd16, 16'b1111111111000010};
      array[{4'h9, 4'h7}] = {6'd16, 16'b1111111111000011};
      array[{4'h9, 4'h8}] = {6'd16, 16'b1111111111000100};
      array[{4'h9, 4'h9}] = {6'd16, 16'b1111111111000101};
      array[{4'h9, 4'hA}] = {6'd16, 16'b1111111111000110};
      array[{4'hA, 4'h1}] = {6'd9, 16'b0000000111111010};
      array[{4'hA, 4'h2}] = {6'd16, 16'b1111111111000111};
      array[{4'hA, 4'h3}] = {6'd16, 16'b1111111111001000};
      array[{4'hA, 4'h4}] = {6'd16, 16'b1111111111001001};
      array[{4'hA, 4'h5}] = {6'd16, 16'b1111111111001010};
      array[{4'hA, 4'h6}] = {6'd16, 16'b1111111111001011};
      array[{4'hA, 4'h7}] = {6'd16, 16'b1111111111001100};
      array[{4'hA, 4'h8}] = {6'd16, 16'b1111111111001101};
      array[{4'hA, 4'h9}] = {6'd16, 16'b1111111111001110};
      array[{4'hA, 4'hA}] = {6'd16, 16'b1111111111001111};
      array[{4'hB, 4'h1}] = {6'd10, 16'b0000001111111001};
      array[{4'hB, 4'h2}] = {6'd16, 16'b1111111111010000};
      array[{4'hB, 4'h3}] = {6'd16, 16'b1111111111010001};
      array[{4'hB, 4'h4}] = {6'd16, 16'b1111111111010010};
      array[{4'hB, 4'h5}] = {6'd16, 16'b1111111111010011};
      array[{4'hB, 4'h6}] = {6'd16, 16'b1111111111010100};
      array[{4'hB, 4'h7}] = {6'd16, 16'b1111111111010101};
      array[{4'hB, 4'h8}] = {6'd16, 16'b1111111111010110};
      array[{4'hB, 4'h9}] = {6'd16, 16'b1111111111010111};
      array[{4'hB, 4'hA}] = {6'd16, 16'b1111111111011000};
      array[{4'hC, 4'h1}] = {6'd10, 16'b0000001111111010};
      array[{4'hC, 4'h2}] = {6'd16, 16'b1111111111011001};
      array[{4'hC, 4'h3}] = {6'd16, 16'b1111111111011010};
      array[{4'hC, 4'h4}] = {6'd16, 16'b1111111111011011};
      array[{4'hC, 4'h5}] = {6'd16, 16'b1111111111011100};
      array[{4'hC, 4'h6}] = {6'd16, 16'b1111111111011101};
      array[{4'hC, 4'h7}] = {6'd16, 16'b1111111111011110};
      array[{4'hC, 4'h8}] = {6'd16, 16'b1111111111011111};
      array[{4'hC, 4'h9}] = {6'd16, 16'b1111111111100000};
      array[{4'hC, 4'hA}] = {6'd16, 16'b1111111111100001};
      array[{4'hD, 4'h1}] = {6'd11, 16'b0000011111111000};
      array[{4'hD, 4'h2}] = {6'd16, 16'b1111111111100010};
      array[{4'hD, 4'h3}] = {6'd16, 16'b1111111111100011};
      array[{4'hD, 4'h4}] = {6'd16, 16'b1111111111100100};
      array[{4'hD, 4'h5}] = {6'd16, 16'b1111111111100101};
      array[{4'hD, 4'h6}] = {6'd16, 16'b1111111111100110};
      array[{4'hD, 4'h7}] = {6'd16, 16'b1111111111100111};
      array[{4'hD, 4'h8}] = {6'd16, 16'b1111111111101000};
      array[{4'hD, 4'h9}] = {6'd16, 16'b1111111111101001};
      array[{4'hD, 4'hA}] = {6'd16, 16'b1111111111101010};
      array[{4'hE, 4'h1}] = {6'd16, 16'b1111111111101011};
      array[{4'hE, 4'h2}] = {6'd16, 16'b1111111111101100};
      array[{4'hE, 4'h3}] = {6'd16, 16'b1111111111101101};
      array[{4'hE, 4'h4}] = {6'd16, 16'b1111111111101110};
      array[{4'hE, 4'h5}] = {6'd16, 16'b1111111111101111};
      array[{4'hE, 4'h6}] = {6'd16, 16'b1111111111110000};
      array[{4'hE, 4'h7}] = {6'd16, 16'b1111111111110001};
      array[{4'hE, 4'h8}] = {6'd16, 16'b1111111111110010};
      array[{4'hE, 4'h9}] = {6'd16, 16'b1111111111110011};
      array[{4'hE, 4'hA}] = {6'd16, 16'b1111111111110100};
      array[{4'hF, 4'h0}] = {6'd11, 16'b0000011111111001};
      array[{4'hF, 4'h1}] = {6'd16, 16'b1111111111110101};
      array[{4'hF, 4'h2}] = {6'd16, 16'b1111111111110110};
      array[{4'hF, 4'h3}] = {6'd16, 16'b1111111111110111};
      array[{4'hF, 4'h4}] = {6'd16, 16'b1111111111111000};
      array[{4'hF, 4'h5}] = {6'd16, 16'b1111111111111001};
      array[{4'hF, 4'h6}] = {6'd16, 16'b1111111111111010};
      array[{4'hF, 4'h7}] = {6'd16, 16'b1111111111111011};
      array[{4'hF, 4'h8}] = {6'd16, 16'b1111111111111100};
      array[{4'hF, 4'h9}] = {6'd16, 16'b1111111111111101};
      array[{4'hF, 4'hA}] = {6'd16, 16'b1111111111111110};
    end else begin
      array[{4'h0, 4'h0}] = {6'd2, 16'b0000000000000000};
      array[{4'h0, 4'h1}] = {6'd2, 16'b0000000000000001};
      array[{4'h0, 4'h2}] = {6'd3, 16'b0000000000000100};
      array[{4'h0, 4'h3}] = {6'd4, 16'b0000000000001010};
      array[{4'h0, 4'h4}] = {6'd5, 16'b0000000000011000};
      array[{4'h0, 4'h5}] = {6'd5, 16'b0000000000011001};
      array[{4'h0, 4'h6}] = {6'd6, 16'b0000000000111000};
      array[{4'h0, 4'h7}] = {6'd7, 16'b0000000001111000};
      array[{4'h0, 4'h8}] = {6'd9, 16'b0000000111110100};
      array[{4'h0, 4'h9}] = {6'd10, 16'b0000001111110110};
      array[{4'h0, 4'hA}] = {6'd12, 16'b0000111111110100};
      array[{4'h1, 4'h1}] = {6'd4, 16'b0000000000001011};
      array[{4'h1, 4'h2}] = {6'd6, 16'b0000000000111001};
      array[{4'h1, 4'h3}] = {6'd8, 16'b0000000011110110};
      array[{4'h1, 4'h4}] = {6'd9, 16'b0000000111110101};
      array[{4'h1, 4'h5}] = {6'd11, 16'b0000011111110110};
      array[{4'h1, 4'h6}] = {6'd12, 16'b0000111111110101};
      array[{4'h1, 4'h7}] = {6'd16, 16'b1111111110001000};
      array[{4'h1, 4'h8}] = {6'd16, 16'b1111111110001001};
      array[{4'h1, 4'h9}] = {6'd16, 16'b1111111110001010};
      array[{4'h1, 4'hA}] = {6'd16, 16'b1111111110001011};
      array[{4'h2, 4'h1}] = {6'd5, 16'b0000000000011010};
      array[{4'h2, 4'h2}] = {6'd8, 16'b0000000011110111};
      array[{4'h2, 4'h3}] = {6'd10, 16'b0000001111110111};
      array[{4'h2, 4'h4}] = {6'd12, 16'b0000111111110110};
      array[{4'h2, 4'h5}] = {6'd15, 16'b0111111111000010};
      array[{4'h2, 4'h6}] = {6'd16, 16'b1111111110001100};
      array[{4'h2, 4'h7}] = {6'd16, 16'b1111111110001101};
      array[{4'h2, 4'h8}] = {6'd16, 16'b1111111110001110};
      array[{4'h2, 4'h9}] = {6'd16, 16'b1111111110001111};
      array[{4'h2, 4'hA}] = {6'd16, 16'b1111111110010000};
      array[{4'h3, 4'h1}] = {6'd5, 16'b0000000000011011};
      array[{4'h3, 4'h2}] = {6'd8, 16'b0000000011111000};
      array[{4'h3, 4'h3}] = {6'd10, 16'b0000001111111000};
      array[{4'h3, 4'h4}] = {6'd12, 16'b0000111111110111};
      array[{4'h3, 4'h5}] = {6'd16, 16'b1111111110010001};
      array[{4'h3, 4'h6}] = {6'd16, 16'b1111111110010010};
      array[{4'h3, 4'h7}] = {6'd16, 16'b1111111110010011};
      array[{4'h3, 4'h8}] = {6'd16, 16'b1111111110010100};
      array[{4'h3, 4'h9}] = {6'd16, 16'b1111111110010101};
      array[{4'h3, 4'hA}] = {6'd16, 16'b1111111110010110};
      array[{4'h4, 4'h1}] = {6'd6, 16'b0000000000111010};
      array[{4'h4, 4'h2}] = {6'd9, 16'b0000000111110110};
      array[{4'h4, 4'h3}] = {6'd16, 16'b1111111110010111};
      array[{4'h4, 4'h4}] = {6'd16, 16'b1111111110011000};
      array[{4'h4, 4'h5}] = {6'd16, 16'b1111111110011001};
      array[{4'h4, 4'h6}] = {6'd16, 16'b1111111110011010};
      array[{4'h4, 4'h7}] = {6'd16, 16'b1111111110011011};
      array[{4'h4, 4'h8}] = {6'd16, 16'b1111111110011100};
      array[{4'h4, 4'h9}] = {6'd16, 16'b1111111110011101};
      array[{4'h4, 4'hA}] = {6'd16, 16'b1111111110011110};
      array[{4'h5, 4'h1}] = {6'd6, 16'b0000000000111011};
      array[{4'h5, 4'h2}] = {6'd10, 16'b0000001111111001};
      array[{4'h5, 4'h3}] = {6'd16, 16'b1111111110011111};
      array[{4'h5, 4'h4}] = {6'd16, 16'b1111111110100000};
      array[{4'h5, 4'h5}] = {6'd16, 16'b1111111110100001};
      array[{4'h5, 4'h6}] = {6'd16, 16'b1111111110100010};
      array[{4'h5, 4'h7}] = {6'd16, 16'b1111111110100011};
      array[{4'h5, 4'h8}] = {6'd16, 16'b1111111110100100};
      array[{4'h5, 4'h9}] = {6'd16, 16'b1111111110100101};
      array[{4'h5, 4'hA}] = {6'd16, 16'b1111111110100110};
      array[{4'h6, 4'h1}] = {6'd7, 16'b0000000001111001};
      array[{4'h6, 4'h2}] = {6'd11, 16'b0000011111110111};
      array[{4'h6, 4'h3}] = {6'd16, 16'b1111111110100111};
      array[{4'h6, 4'h4}] = {6'd16, 16'b1111111110101000};
      array[{4'h6, 4'h5}] = {6'd16, 16'b1111111110101001};
      array[{4'h6, 4'h6}] = {6'd16, 16'b1111111110101010};
      array[{4'h6, 4'h7}] = {6'd16, 16'b1111111110101011};
      array[{4'h6, 4'h8}] = {6'd16, 16'b1111111110101100};
      array[{4'h6, 4'h9}] = {6'd16, 16'b1111111110101101};
      array[{4'h6, 4'hA}] = {6'd16, 16'b1111111110101110};
      array[{4'h7, 4'h1}] = {6'd7, 16'b0000000001111010};
      array[{4'h7, 4'h2}] = {6'd11, 16'b0000011111111000};
      array[{4'h7, 4'h3}] = {6'd16, 16'b1111111110101111};
      array[{4'h7, 4'h4}] = {6'd16, 16'b1111111110110000};
      array[{4'h7, 4'h5}] = {6'd16, 16'b1111111110110001};
      array[{4'h7, 4'h6}] = {6'd16, 16'b1111111110110010};
      array[{4'h7, 4'h7}] = {6'd16, 16'b1111111110110011};
      array[{4'h7, 4'h8}] = {6'd16, 16'b1111111110110100};
      array[{4'h7, 4'h9}] = {6'd16, 16'b1111111110110101};
      array[{4'h7, 4'hA}] = {6'd16, 16'b1111111110110110};
      array[{4'h8, 4'h1}] = {6'd8, 16'b0000000011111001};
      array[{4'h8, 4'h2}] = {6'd16, 16'b1111111110110111};
      array[{4'h8, 4'h3}] = {6'd16, 16'b1111111110111000};
      array[{4'h8, 4'h4}] = {6'd16, 16'b1111111110111001};
      array[{4'h8, 4'h5}] = {6'd16, 16'b1111111110111010};
      array[{4'h8, 4'h6}] = {6'd16, 16'b1111111110111011};
      array[{4'h8, 4'h7}] = {6'd16, 16'b1111111110111100};
      array[{4'h8, 4'h8}] = {6'd16, 16'b1111111110111101};
      array[{4'h8, 4'h9}] = {6'd16, 16'b1111111110111110};
      array[{4'h8, 4'hA}] = {6'd16, 16'b1111111110111111};
      array[{4'h9, 4'h1}] = {6'd9, 16'b0000000111110111};
      array[{4'h9, 4'h2}] = {6'd16, 16'b1111111111000000};
      array[{4'h9, 4'h3}] = {6'd16, 16'b1111111111000001};
      array[{4'h9, 4'h4}] = {6'd16, 16'b1111111111000010};
      array[{4'h9, 4'h5}] = {6'd16, 16'b1111111111000011};
      array[{4'h9, 4'h6}] = {6'd16, 16'b1111111111000100};
      array[{4'h9, 4'h7}] = {6'd16, 16'b1111111111000101};
      array[{4'h9, 4'h8}] = {6'd16, 16'b1111111111000110};
      array[{4'h9, 4'h9}] = {6'd16, 16'b1111111111000111};
      array[{4'h9, 4'hA}] = {6'd16, 16'b1111111111001000};
      array[{4'hA, 4'h1}] = {6'd9, 16'b0000000111111000};
      array[{4'hA, 4'h2}] = {6'd16, 16'b1111111111001001};
      array[{4'hA, 4'h3}] = {6'd16, 16'b1111111111001010};
      array[{4'hA, 4'h4}] = {6'd16, 16'b1111111111001011};
      array[{4'hA, 4'h5}] = {6'd16, 16'b1111111111001100};
      array[{4'hA, 4'h6}] = {6'd16, 16'b1111111111001101};
      array[{4'hA, 4'h7}] = {6'd16, 16'b1111111111001110};
      array[{4'hA, 4'h8}] = {6'd16, 16'b1111111111001111};
      array[{4'hA, 4'h9}] = {6'd16, 16'b1111111111010000};
      array[{4'hA, 4'hA}] = {6'd16, 16'b1111111111010001};
      array[{4'hB, 4'h1}] = {6'd9, 16'b0000000111111001};
      array[{4'hB, 4'h2}] = {6'd16, 16'b1111111111010010};
      array[{4'hB, 4'h3}] = {6'd16, 16'b1111111111010011};
      array[{4'hB, 4'h4}] = {6'd16, 16'b1111111111010100};
      array[{4'hB, 4'h5}] = {6'd16, 16'b1111111111010101};
      array[{4'hB, 4'h6}] = {6'd16, 16'b1111111111010110};
      array[{4'hB, 4'h7}] = {6'd16, 16'b1111111111010111};
      array[{4'hB, 4'h8}] = {6'd16, 16'b1111111111011000};
      array[{4'hB, 4'h9}] = {6'd16, 16'b1111111111011001};
      array[{4'hB, 4'hA}] = {6'd16, 16'b1111111111011010};
      array[{4'hC, 4'h1}] = {6'd9, 16'b0000000111111010};
      array[{4'hC, 4'h2}] = {6'd16, 16'b1111111111011011};
      array[{4'hC, 4'h3}] = {6'd16, 16'b1111111111011100};
      array[{4'hC, 4'h4}] = {6'd16, 16'b1111111111011101};
      array[{4'hC, 4'h5}] = {6'd16, 16'b1111111111011110};
      array[{4'hC, 4'h6}] = {6'd16, 16'b1111111111011111};
      array[{4'hC, 4'h7}] = {6'd16, 16'b1111111111100000};
      array[{4'hC, 4'h8}] = {6'd16, 16'b1111111111100001};
      array[{4'hC, 4'h9}] = {6'd16, 16'b1111111111100010};
      array[{4'hC, 4'hA}] = {6'd16, 16'b1111111111100011};
      array[{4'hD, 4'h1}] = {6'd11, 16'b0000011111111001};
      array[{4'hD, 4'h2}] = {6'd16, 16'b1111111111100100};
      array[{4'hD, 4'h3}] = {6'd16, 16'b1111111111100101};
      array[{4'hD, 4'h4}] = {6'd16, 16'b1111111111100110};
      array[{4'hD, 4'h5}] = {6'd16, 16'b1111111111100111};
      array[{4'hD, 4'h6}] = {6'd16, 16'b1111111111101000};
      array[{4'hD, 4'h7}] = {6'd16, 16'b1111111111101001};
      array[{4'hD, 4'h8}] = {6'd16, 16'b1111111111101010};
      array[{4'hD, 4'h9}] = {6'd16, 16'b1111111111101011};
      array[{4'hD, 4'hA}] = {6'd16, 16'b1111111111101100};
      array[{4'hE, 4'h1}] = {6'd14, 16'b0011111111100000};
      array[{4'hE, 4'h2}] = {6'd16, 16'b1111111111101101};
      array[{4'hE, 4'h3}] = {6'd16, 16'b1111111111101110};
      array[{4'hE, 4'h4}] = {6'd16, 16'b1111111111101111};
      array[{4'hE, 4'h5}] = {6'd16, 16'b1111111111110000};
      array[{4'hE, 4'h6}] = {6'd16, 16'b1111111111110001};
      array[{4'hE, 4'h7}] = {6'd16, 16'b1111111111110010};
      array[{4'hE, 4'h8}] = {6'd16, 16'b1111111111110011};
      array[{4'hE, 4'h9}] = {6'd16, 16'b1111111111110100};
      array[{4'hE, 4'hA}] = {6'd16, 16'b1111111111110101};
      array[{4'hF, 4'h0}] = {6'd10, 16'b0000001111111010};
      array[{4'hF, 4'h1}] = {6'd15, 16'b0111111111000011};
      array[{4'hF, 4'h2}] = {6'd16, 16'b1111111111110110};
      array[{4'hF, 4'h3}] = {6'd16, 16'b1111111111110111};
      array[{4'hF, 4'h4}] = {6'd16, 16'b1111111111111000};
      array[{4'hF, 4'h5}] = {6'd16, 16'b1111111111111001};
      array[{4'hF, 4'h6}] = {6'd16, 16'b1111111111111010};
      array[{4'hF, 4'h7}] = {6'd16, 16'b1111111111111011};
      array[{4'hF, 4'h8}] = {6'd16, 16'b1111111111111100};
      array[{4'hF, 4'h9}] = {6'd16, 16'b1111111111111101};
      array[{4'hF, 4'hA}] = {6'd16, 16'b1111111111111110};
    end
end
endmodule
