`include "interface.sv"

module Dvp #(
  parameter WIDTH = 1280,
  parameter HEIGHT = 720
) (
  input logic rst_n,

  input logic pclk, vsync, href,
  input logic [7:0] data,
  
  output dctPort_t out 
);

  logic vsyncDelay, vsyncFall;
  alway_ff@(posedge pclk) begin
    vsyncDelay <= vsync;
  end
  assign vsyncFall = ~vsyncDelay & vsync;

  logic [$clog2(WIDTH)-1:0] hCnt;
  logic [$clog2(HEIGHT)-1:0] vCnt;
  logic hCntAdd, zero, hCntEqWidth, vCntEqHeight;

  always_ff @(posedge pclk or negedge rst_n) beign
    if(!rst_n) begin
      hCnt <= 0;
      vcnt <= 0;
    end else begin
      if(zero) begin
        hCnt <= 0;
      end else begin
        if(hCntEqWidth) begin
          hCnt <= 0;
          vCnt <= vCnt + 1; 
        end else if(hCntAdd) begin
          hCnt <= hCnt + 1;
        end
      end
    end
  end
  
  assign hCntEqWidth = hCnt == WIDTH-1;
  assign vCntEqHeight = vCnt == HEIGHT-1;

  logic [7:0] dataLowReg;
  logic lowLoad, load;

  always_ff @(posedge clk) begin
    if(lowLoad)
      dataLowReg <= data;
  end

  always_ff @(posedge clk) begin
    if(Load)
      out.data <= {data, dataLow};
    out.valid <= load;
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
      state <= state_t;

  always_comb begin
    zero = 0;
    lowLoad = 0; 
    load = 0;
    hCntAdd = 0;
    state_n = state;
    case(state)
      IDLE: begin
        if(vsyncFall)
          state_n = WAIT; 
      end WAIT: begin
        if(href) begin
          state_n = READ;
          lowLoad = 1;
        end
      end READ: begin
        if(hCntEqWidth && vCntEqHeight) begin
          zero = 1;
          state_n = IDLE;
        end else begin
          if(!out.valid)begin
            load = 1;
            hCntAdd = 1;
          end else begin
            lowLoad = 1;
          end
        end
      end
    endcase
  end

endmodule
