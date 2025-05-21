`timescale 1ns / 1ps
`include "uart.svh"

module UartTop (
  input logic clk, rst_n,
(* MARK_DEBUG="true" *)  input logic rx,
(* MARK_DEBUG="true" *)  output logic tx
);

  struct {enum logic[1:0] {INIT, SENDING, LOOP} current, next;} state;
  logic [7:0] sendBuf [12:0];
  struct {logic [$clog2(13)-1:0] current, next;} index;
  UartIF rxPort(), txPort();

  always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      state.current <= INIT;
      index.current <= 0;
    end else begin
      state.current <= state.next;
      index.current <= index.next;
    end
  end

  always_comb begin
    state.next = state.current;
    index.next = index.current;

    txPort.data = sendBuf[index.current];
    txPort.valid = 0;
    rxPort.ready = 1;
    case(state.current)
      INIT: begin
        state.next = SENDING;
      end
      SENDING: begin
        if(txPort.ready) begin      
          if(index.current < 13) begin
            txPort.valid = 1;
            index.next++;
          end else if(index.current == 13) begin
            index.next++;
          end else begin
            state.next = LOOP;
          end
        end
      end
      LOOP: begin
        txPort.data = rxPort.data;
        txPort.valid = rxPort.valid;
        rxPort.ready = txPort.ready;
      end
    endcase
  end

  UartRx #(50000000, 115200) rxModule (
    clk, rst_n, rxPort, rx
  );

  UartTx #(50000000, 115200) txModule (
    clk, rst_n, txPort, tx
  );

  initial begin
      sendBuf[0]  = "h";
      sendBuf[1]  = "e";
      sendBuf[2]  = "l";
      sendBuf[3]  = "l";
      sendBuf[4]  = "o";
      sendBuf[5]  = "f";
      sendBuf[6]  = "p";
      sendBuf[7]  = "g";
      sendBuf[8]  = "a";
      sendBuf[9]  = ".";
      sendBuf[10] = "c";
      sendBuf[11] = "o";
      sendBuf[12] = "m";
  end

endmodule
