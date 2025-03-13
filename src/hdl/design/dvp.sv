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
  logic [$clog2(WIDTH)-1:0] hCntFF,
  logic [$clog2(HEIGHT)-1:0] vCntFF
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
  always_ff @(posedge pclk or negedge rst_n) begin
    if(!rst_n) begin
      hCntFF <= 0;
      vCntFF <= 0;
    end else begin
      hCntFF <= hCnt;
      vCntFF <= vCnt;
    end
  end
  
  assign hCntEqWidth = hCnt == WIDTH-1;
  assign vCntEqHeight = vCnt == HEIGHT-1;

  logic [8*SHIFT_WIDTH-1:0] dataHightReg;
  logic lowLoad, load, valid;
  logic [SHIFT_WIDTH-1:0] validDelay;

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
  
  state_t state, state_n;
  always_ff @(posedge pclk or negedge rst_n)
    if(!rst_n)
      state <= IDLE;
    else
      state <= state_n;

  always_comb begin
    zero = 0;
    lowLoad = 0; 
    load = 0;
    valid = 0;
    hCntAdd = 0;
    vCntAdd = 0;
    state_n = state;
    case(state)
      IDLE: begin
        if(vsyncFall)
          state_n = WAIT; 
      end WAIT: begin
        if(href) begin
          state_n = READ;
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
            state_n = IDLE;
          end else begin 
            state_n = WAIT;
            vCntAdd = 1;
          end
        end
      end
    endcase
  end

endmodule
