`include "interface.sv"

module compressStreamGenator #(
  parameter ROW = 3
) (
  input logic clk, rst_n,
  input huffman_pkg::HuffmanBus_t in[ROW],
  output huffman_pkg::HuffmanBus_t out
);
  import huffman_pkg::*;
  // input logic clk, rst_n;
  // input HuffmanBus_t in[ROW]; 
  // output HuffmanBus_t out; 

  HuffmanBus_t huffmanBuf[ROW];
  logic [$clog2(ROW)-1:0] channalSel;
  generate 
    for(genvar i=0; i<ROW; i++) begin
      fifoWr_if #($bits(HuffmanBus_t)-1) bufIn (clk);
      fifoRd_if #($bits(HuffmanBus_t)-1) bufOut (clk);
      ShiftFIFO #($bits(HuffmanBus_t)-1, 128) inBuf (
        clk, rst_n, 1'b0,
        bufIn, bufOut
      );
      assign bufIn.data = {in[i].data, in[i].sop, in[i].eop, in[i].done};
      assign bufIn.en = in[i].valid;
      assign bufOut.en = !bufOut.empty & channalSel == i;

      assign huffmanBuf[i].valid = !bufOut.empty;
      assign {huffmanBuf[i].data, huffmanBuf[i].sop, huffmanBuf[i].eop, huffmanBuf[i].done} = bufOut.data;
    end
  endgenerate

  always_ff @(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
      channalSel <= 0;
    end else begin
      if(huffmanBuf[channalSel].done & huffmanBuf[channalSel].valid)
        channalSel <= channalSel < ROW - 1 ? channalSel + 1 : 0;
    end
  end

  HuffmanBus_t FixedLengthGenIn;
  always_comb begin
    FixedLengthGenIn = huffmanBuf[channalSel];
    FixedLengthGenIn.done = huffmanBuf[ROW-1].done;
    FixedLengthGenIn.done &= FixedLengthGenIn.eop;
  end
  FixedLengthGen FixedLengthGen(clk, rst_n, FixedLengthGenIn, out);
endmodule
