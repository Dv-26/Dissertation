`include "interface.sv"

module compressStreamGenator #(
  parameter ROW = 3
) (
  input logic clk, rst_n,
  input huffman_pkg::HuffmanBus_t in[ROW],
  output huffman_pkg::HuffmanBus_t out
);
  import huffman_pkg::*;

  int doneCounter[ROW] = {0, 0, 0};
  HuffmanBus_t huffmanBuf[ROW];
  logic [$clog2(ROW)-1:0] channalSel;
  generate 
    for(genvar i=0; i<ROW; i++) begin
      fifoWr_if #($bits(HuffmanBus_t)-1) bufIn (clk);
      fifoRd_if #($bits(HuffmanBus_t)-1) bufOut (clk);
      fifo_generator_1 inBuf (
        .clk(clk),      // input wire clk
        .rst(!rst_n),      // input wire rst
        .din(bufIn.data),      // input wire [73 : 0] din
        .wr_en(bufIn.en),  // input wire wr_en
        .rd_en(bufOut.en),  // input wire rd_en
        .dout(bufOut.data),    // output wire [73 : 0] dout
        .full(bufIn.full),    // output wire full
        .empty(bufOut.empty)  // output wire empty
      );
      // syncFIFO #($bits(HuffmanBus_t)-1, 512, 1) inBuf (clk, rst_n, bufIn, bufOut);

      if(i == 0)
        assign bufIn.data = {in[i].data, in[i].sop, 1'b0, in[i].done};
      else if(i == ROW-1)
        assign bufIn.data = {in[i].data, 1'b0, in[i].eop, in[i].done};
      else
        assign bufIn.data = {in[i].data, 1'b0, 1'b0, in[i].done};

      assign bufIn.en = in[i].valid;
      assign bufOut.en = !bufOut.empty & channalSel == i;

      assign huffmanBuf[i].valid = !bufOut.empty;
      assign {huffmanBuf[i].data, huffmanBuf[i].sop, huffmanBuf[i].eop, huffmanBuf[i].done} = bufOut.data;

      always_ff @(posedge clk)
        if(in[i].valid & in[i].done)
          doneCounter[i] ++;

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

  HuffmanBus_t FixedLengthGenIn, FixedLengthGenOut;
  always_comb begin
    FixedLengthGenIn = huffmanBuf[channalSel];
    FixedLengthGenIn.done &= FixedLengthGenIn.eop;
  end
  FixedLengthGen FixedLengthGen(clk, rst_n, FixedLengthGenIn, out);
  // eopSopGen eopSopGen(clk, rst_n, FixedLengthGenOut, out);
endmodule

module eopSopGen (
  input logic clk, rst_n,
  input huffman_pkg::HuffmanBus_t in,
  output huffman_pkg::HuffmanBus_t out
);
  import huffman_pkg::*;
  struct {HuffmanBus_t current, next;} outReg;
  assign out = outReg.current;
  always_ff @(posedge clk or negedge rst_n)
    outReg.current <= !rst_n ? '0 : outReg.next;

  struct {enum logic[1:0]{WAIT_SOP, WAIT_EOP} current, next;} state;
  always_ff @(posedge clk or negedge rst_n)
    state.current <= !rst_n ? WAIT_SOP : state.next;
  always_comb begin
    state.next = state.current;
    outReg.next = in;
    outReg.next.eop = 0;
    case(state.current)
      WAIT_SOP: begin
        if(in.valid & in.sop)
          state.next = WAIT_EOP;
      end
      WAIT_EOP: begin
        outReg.next.sop = 0;
        if(in.valid & in.done & in.eop) begin
          state.next = WAIT_SOP;
          outReg.next.data.code |= (1 << (CODE_W - in.data.size)) - 1;
          outReg.next.eop = in.eop;
        end
      end
    endcase
  end
endmodule
