`include "interface.sv"

module Dvp #(
  parameter WIDTH = 16,
  parameter HEIGHT = 16,
  parameter DATA_FORMAT = "RGB888"
) (
  input logic rst_n,

  input logic pclk, vsync, href,
  input logic [7:0] data,
  output dataPort_t out,
  output logic [$clog2(WIDTH)-1:0] hCntFF,
  output logic [$clog2(HEIGHT)-1:0] vCntFF
);
  localparam SHIFT_WIDTH = DATA_FORMAT == "RGB888" ? 2 : 1;

  logic vsyncDelay, vsyncFall;
  always_ff@(posedge pclk) begin
    vsyncDelay <= vsync;
  end
  assign vsyncFall = ~vsyncDelay & vsync;

  logic [$clog2(WIDTH)-1:0] hCnt;
  logic [$clog2(HEIGHT)-1:0] vCnt;
  logic vCntAdd, hCntAdd, zero, hCntEqWidth, vCntEqHeight;

  always_ff @(posedge pclk or negedge rst_n) begin
    if(!rst_n) begin
      hCnt <= 0;
      vCnt <= 0;
    end else begin
      if(zero) begin
        hCnt <= 0;
      end else begin
        if(vCntAdd) begin
          hCnt <= 0;
          vCnt <= vCnt + 1; 
        end else if(hCntAdd) begin
          hCnt <= hCnt + 1;
        end
      end
    end
  end

  logic [8*SHIFT_WIDTH-1:0] dataHightReg;
  logic lowLoad, load, valid;
  logic [SHIFT_WIDTH-1:0] validDelay;

  always_ff @(posedge pclk or negedge rst_n) begin
    if(!rst_n) begin
      hCntFF <= 0;
      vCntFF <= 0;
    end else begin
      hCntFF <= hCnt;
      vCntFF <= vCnt;
      out.sop <= (hCnt < 8 && vCnt < 8) & load;
      out.eop <= (hCnt >= WIDTH - 8  && vCnt >= HEIGHT - 8) & load;
    end
  end
  
  assign hCntEqWidth = hCnt == WIDTH-1;
  assign vCntEqHeight = vCnt == HEIGHT-1;

  int i;
  always_ff @(posedge pclk) begin
    if(lowLoad) begin
      dataHightReg <= {dataHightReg, data};
    end
  end

  always_ff @(posedge pclk) begin
    if(load) 
      out.data <= {dataHightReg, data};
  end

  always_ff @(posedge pclk or negedge rst_n)begin
    if(!rst_n)
      validDelay <= '0;
    else
      {out.valid, validDelay} <= {validDelay, valid};
  end

  typedef enum logic [1:0]{
    IDLE,
    WAIT,
    READ
  } state_t;
  
  struct {state_t current, next;} state;
  always_ff @(posedge pclk or negedge rst_n)
    state.current <= !rst_n ? IDLE : state.next;
  always_comb begin
    zero = 0;
    lowLoad = 0; 
    load = 0;
    valid = 0;
    hCntAdd = 0;
    vCntAdd = 0;
    state.next = state.current;
    case(state.current)
      IDLE: begin
        if(vsyncFall)
          state.next = WAIT; 
      end WAIT: begin
        if(href) begin
          state.next = READ;
          lowLoad = 1;
          valid = 1;
        end
      end READ: begin
        if(href) begin
          if(validDelay[SHIFT_WIDTH-1])begin
            load = 1;
            hCntAdd = 1;
          end else begin
            lowLoad = 1;
          end
          if(out.valid)
            valid = 1;
        end else begin
          if(hCntEqWidth && vCntEqHeight) begin
            zero = 1;
            state.next = IDLE;
          end else begin 
            state.next = WAIT;
            vCntAdd = 1;
          end
        end
      end
    endcase
  end

endmodule
