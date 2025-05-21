`timescale 1ns / 1ps

module UartTx #(
  parameter CLK_FREQ = 50000000,
  parameter BAUD_RATE = 115200
) (
  input logic clk, rst_n,
  UartIF.slave in,
  output logic tx
);

  localparam BAUD_TICK = CLK_FREQ / BAUD_RATE;
  logic [$clog2(BAUD_TICK)-1:0] baudCnt;
  logic [$clog2($bits(in.data)):0] bitCnt;
  logic [9:0] shiftReg;
  enum logic {IDLE, BUSY} state;
  always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      state <= IDLE;
      // in.ready <= 1'b1;
      baudCnt <= 0;
      bitCnt <= 0;
      shiftReg <= '1;
    end else begin
      case (state)
        IDLE : begin
          if(in.valid) begin
            state <= BUSY;
            shiftReg <= {1'b1, in.data, 1'b0};
          end
        end
        BUSY : begin
          if(baudCnt == BAUD_TICK - 1) begin
            baudCnt <= 0;
            shiftReg <= {1'b1, shiftReg[9:1]};
            bitCnt <= bitCnt + 1;
            if(bitCnt == 9) begin
              // in.ready <= 1'b1;
              state <= IDLE;
              bitCnt <= 0;
            end
          end else begin
            baudCnt <= baudCnt + 1;
          end
        end
      endcase
    end
  end
  assign tx = shiftReg[0];
  assign in.ready = !(in.valid || state == BUSY);

endmodule
