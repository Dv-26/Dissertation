`include "uart.svh"

module UartRx #(
  parameter CLK_FREQ = 50_000_000,
  parameter BAUD_RATE = 115200
) (
  input logic clk, rst_n,
  UartIF.master out,
  input logic rx
);
  localparam BAUD_TICK = CLK_FREQ / BAUD_RATE;
  localparam HALF_BAUD = BAUD_TICK / 2;

  logic sync[2], fall;
  always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      sync[1] <= 1'b1;
      sync[0] <= 1'b1;
    end else begin 
      sync[1] <= sync[0];
      sync[0] <= rx;
    end
  end
  assign fall = sync[1] & !sync[0];


  enum logic {IDLE, BUSY} state;
  logic [$clog2(BAUD_TICK)-1:0] baudCnt;
  logic [$clog2($bits(out.data)):0] bitCnt;
  logic [7:0] shiftReg;
  always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      state <= IDLE;
      baudCnt <= 0;
      bitCnt <= 0;
      shiftReg <= 0;
      out.data <= 0;
      out.valid <= 0;
    end else begin
      case(state)
        IDLE: begin
          out.valid <= 1'b0;
          if(fall & out.ready)
            state <= BUSY;
        end
        BUSY: begin
          baudCnt <= baudCnt + 1;
          if((bitCnt == 0 && baudCnt == HALF_BAUD) || (baudCnt == BAUD_TICK)) begin
            baudCnt <= 0;
            bitCnt <= bitCnt + 1;

            if(bitCnt >= 1 && bitCnt <= 8)
              shiftReg <= {rx, shiftReg[7:1]};
          end

          if(bitCnt == 9) begin
            out.data <= shiftReg;
            out.valid <= 1'b1;
            state <= IDLE;
            bitCnt <= 0;
          end
        end
      endcase
    end
  end

endmodule

