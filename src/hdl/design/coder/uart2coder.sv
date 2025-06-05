`include "interface.sv"
`include "uart.svh"

module Uart2coder# (
  parameter WIDTH = 1280,
  parameter HEIGHT = 720
) (
  input logic clk, rst_n,
  UartIF.slave in,
  output dataPort_t out
);

  struct {
    logic [1:0] value;
    logic eq;
  } cnt;

  struct {
    logic [$clog2(WIDTH*HEIGHT)-1:0] value;
    logic eq;
    logic eqZero;
  } pixelCnt;

  always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      cnt.value <= 0;
      pixelCnt.value <= 0;
    end else if(in.valid | cnt.eq) begin
      if(cnt.eq) begin
        cnt.value <= 0;
        pixelCnt.value <= pixelCnt.eq ? 0 : pixelCnt.value + 1;
      end else begin
        cnt.value <= cnt.value + 1;
      end
    end
  end

  assign cnt.eq = cnt.value == 3;
  assign pixelCnt.eq = pixelCnt.value == ((WIDTH*HEIGHT) - 1);
  assign pixelCnt.eqZero = pixelCnt.value == 0;

  logic [$bits(in.data)-1:0] splic [3];
  always_ff @(posedge clk) begin
    if(in.valid) begin
      splic[0] <= in.data;
      splic[1] <= splic[0];
      splic[2] <= splic[1];
    end
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      out.data <= '0;
      out.valid <= 1'b0;
      out.eop <= 1'b0;
      out.sop <= 1'b0;
    end else if(cnt.eq) begin
      out.data <= {splic[2], splic[1], splic[0]};
      out.valid <= 1'b1;
      out.sop <= pixelCnt.eqZero;
      out.eop <= pixelCnt.eq;
    end else begin
      out.valid <= 1'b0;
      out.eop <= 1'b0;
      out.sop <= 1'b0;
    end
  end

  assign in.ready = 1'b1;

endmodule

module Coder2uart (
  input logic exClk, inClk, rst_n,
  input huffman_pkg::HuffmanBus_t in,
  UartIF.master out
); 

  fifoWr_if #($bits(in.data.code)) bufIn(inClk);
  fifoRd_if #($bits(in.data.code)/8) bufOut(exClk);

  // fifo_generator_0 piso (
  //   .rst(!rst_n),        // input wire rst
  //   .wr_clk(inClk),  // input wire wr_clk
  //   .rd_clk(exClk),  // input wire rd_clk
  //   .din(bufIn.data),        // input wire [63 : 0] din
  //   .wr_en(bufIn.en),    // input wire wr_en
  //   .rd_en(bufOut.en),    // input wire rd_en
  //   .dout(bufOut.data),      // output wire [7 : 0] dout
  //   .full(bufIn.full),      // output wire full
  //   .empty(bufOut.empty)    // output wire empty
  // ); 
  PISO #($bits(in.data.code), 512, 8) piso (rst_n, bufIn, bufOut);
  assign {bufIn.data, bufIn.en} = {in.data.code, in.valid};

  (* MARK_DEBUG="true" *) logic full;
  assign full = bufIn.full;
  struct {
    struct{
      logic [$bits(out.data)-1:0] data;
      logic valid;
    } current, next;
  } outReg;
  assign {out.data, out.valid} = {outReg.current.data, outReg.current.valid};
  struct{enum logic[1:0] {NORMAL, OUT_ZERO} current, next;} state;

  always_ff @(posedge exClk or negedge rst_n) begin
    if(!rst_n) begin
      state.current <= NORMAL;
      outReg.current.data <= 0;
      outReg.current.valid <= 0;
    end else begin
      state.current <= state.next;
      outReg.current.data <= outReg.next.data;
      outReg.current.valid <= outReg.next.valid;
    end
  end
  always_comb begin
    state.next = state.current;
    outReg.next.data = bufOut.data;
    outReg.next.valid = 0;
    bufOut.en = 0;
    case(state.current)
      NORMAL: begin
        if(out.ready & !bufOut.empty) begin
          outReg.next.valid = 1;
          bufOut.en = 1;
          if(&bufOut.data)
            state.next = OUT_ZERO;
        end
      end
      OUT_ZERO: begin
        outReg.next.data = 8'h00;
        if(out.ready) begin
          outReg.next.valid = 1;
          state.next = NORMAL;
        end
      end
    endcase
  end

endmodule

module PISO #(
  parameter WR_WIDTH = 64,
  parameter WR_DEPTH = 3,
  parameter WIDTH_RATIO = 8
) (
  input logic rst_n,
  fifoWr_if.asyncRx wr,
  fifoRd_if.asyncTx rd
);
  localparam RD_WIDTH = WR_WIDTH / WIDTH_RATIO;

  fifoRd_if #(WR_WIDTH) parallelOut (rd.clk);
  asyncFIFO #(WR_WIDTH, WR_DEPTH, 1) asyncFIFO (rst_n, wr, parallelOut);

  logic [RD_WIDTH-1:0] mux [WIDTH_RATIO];
  always_comb begin
    for(int i=0; i<WIDTH_RATIO; i++)
      mux[i] = parallelOut.data[i*RD_WIDTH+ : RD_WIDTH];
  end

  struct {logic [$clog2(WIDTH_RATIO)-1:0] current, next;} cnt;
  always_ff @(posedge rd.clk or negedge rst_n)
    cnt.current <= !rst_n ? WIDTH_RATIO-1 : cnt.next;
  always_comb begin
    cnt.next = cnt.current;
    parallelOut.en = 0;
    if(rd.en & !rd.empty) begin
      if(cnt.current == 0) begin
        parallelOut.en = 1;
        cnt.next = WIDTH_RATIO-1;
      end else begin
        cnt.next --;
      end
    end
  end
  always_ff @(posedge rd.clk or negedge rst_n)
    rd.empty <= !rst_n ? 1 : |cnt.next & parallelOut.empty;

  assign rd.data = mux[cnt.current];
endmodule
