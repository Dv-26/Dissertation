`include "interface.sv"
module PingpongBuf #(
  parameter WIDTH = 1280,
  parameter HEIGHT = 720
) (
  input logic pclk, clk, rst_n,
  input dataPort_t in,
  output dctPort_t out[3] 
);

  localparam BUF_ADDR_W = $clog2(WIDTH) + 3;
  localparam BUF_DEPTH = 2**BUF_ADDR_W;
  typedef struct {
    logic value;
    logic set;
    logic reset;
  } Full_t;

  struct {dctPort_t current, next;} outReg[3];
  always_ff @(posedge clk or negedge rst_n)begin
    if(!rst_n) begin
      outReg[0].current <= '0;
      outReg[1].current <= '0;
      outReg[2].current <= '0;
    end else begin
      outReg[0].current <= outReg[0].next;
      outReg[1].current <= outReg[1].next;
      outReg[2].current <= outReg[2].next;
    end
  end
  assign out = {outReg[2].current, outReg[1].current, outReg[0].current};

  logic [$clog2(WIDTH)-1:0] hCnt;
  logic [$clog2(HEIGHT)-1:0] vCnt;

  always_ff @(posedge pclk or negedge rst_n) begin
    if(!rst_n) begin
      hCnt <= 0;
      vCnt <= 0;
    end else if(in.valid) begin
      if(in.sop) begin
        hCnt <= 1;
        vCnt <= 0; 
      end else if(in.eop) begin
        hCnt <= 0;
        vCnt <= 0; 
      end else if(hCnt == WIDTH-1) begin
        hCnt <= 0;
        vCnt <= vCnt + 1;
      end else begin
        hCnt <= hCnt + 1;
      end
    end
  end

  logic switch;
  assign switch = hCnt == WIDTH-1 && (&vCnt[2:0]) && in.valid;

  ramRd_if #($bits(dataPort_t)-1, BUF_DEPTH) buf0Out (clk);
  ramWr_if #($bits(dataPort_t)-1, BUF_DEPTH) buf0In (pclk);
  Full_t buf0Full, buf1Full;
  logic buf0FullSet, buf1FullSet;
  CdcPulse buf0Set (rst_n, pclk, buf0FullSet, clk, buf0Full.set);

  ramRd_if #($bits(dataPort_t)-1, BUF_DEPTH) buf1Out (clk);
  ramWr_if #($bits(dataPort_t)-1, BUF_DEPTH) buf1In (pclk);
  CdcPulse buf1Set (rst_n, pclk, buf1FullSet, clk, buf1Full.set);

  always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      buf0Full.value <= 1'b0;
    end else if(buf0Full.value & buf0Full.reset) begin
      buf0Full.value <= 1'b0;
    end else if(~buf0Full.value & buf0Full.set) begin
      buf0Full.value <= 1'b1;
    end
  end
  Ram #($bits(dataPort_t)-1, BUF_DEPTH) buf0 (buf0In, buf0Out);

  always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      buf1Full.value <= 1'b0;
    end else if(buf1Full.value & buf1Full.reset) begin
      buf1Full.value <= 1'b0;
    end else if(~buf1Full.value & buf1Full.set) begin
      buf1Full.value <= 1'b1;
    end
  end
  Ram #($bits(dataPort_t)-1, BUF_DEPTH) buf1 (buf1In, buf1Out);

  logic rdStart, rdDone, rdValid;
  logic [BUF_ADDR_W-1:0] rdAddr; 
  RdAddrGen #(WIDTH) rdAddrGen (clk, rst_n, rdStart, rdDone, rdValid, rdAddr);

  logic wrBufSel, rdBufSel;
  assign buf1In.data = {in.data, in.sop, in.eop};
  assign buf1In.addr = {vCnt[2:0], hCnt};
  assign buf0In.data = {in.data, in.sop, in.eop};
  assign buf0In.addr = {vCnt[2:0], hCnt};
  assign {buf0In.en, buf1In.en} = wrBufSel ?
    {1'b0, in.valid} :
    {in.valid, 1'b0};
  assign buf0Out.addr = rdAddr;
  assign buf1Out.addr = rdAddr;
  assign {buf0Out.en, buf1Out.en} = rdBufSel ?
    {1'b0, rdValid}:
    {rdValid, 1'b0};

  logic eop, sop;
  logic rdValidDelay;

  Delay #(1, 1) validDelay (clk, rst_n, rdValid, rdValidDelay);
  struct{logic current, next;} eopFlag;
  always_ff @(posedge clk or negedge rst_n)
    eopFlag.current <= !rst_n ? 0 : eopFlag.next;
  always_comb begin
    {
      outReg[2].next.data,
      outReg[1].next.data,
      outReg[0].next.data
    } = '0;

    {
      outReg[2].next.data[7:0],
      outReg[1].next.data[7:0],
      outReg[0].next.data[7:0],
      sop, eop 
    } = rdBufSel? buf1Out.data : buf0Out.data;

    {outReg[2].next.valid, outReg[1].next.valid, outReg[0].next.valid} = {3{rdValidDelay}};
    {outReg[2].next.sop, outReg[1].next.sop, outReg[0].next.sop} = {3{sop}};
    {outReg[2].next.eop, outReg[1].next.eop, outReg[0].next.eop} = '0;

    eopFlag.next = eopFlag.current;
    if(eopFlag.current) begin
      if(rdDone) begin
        {outReg[2].next.eop, outReg[1].next.eop, outReg[0].next.eop} = '1;
        eopFlag.next = 0;
      end
    end else begin
      if(eop)
        eopFlag.next = 1;
    end
  end


  typedef enum logic {
    WR_BUF0,
    WR_BUF1
  } wrState_t;
  (* MARK_DEBUG="true" *)wrState_t wrState, wrState_n;
  always_ff @(posedge pclk or negedge rst_n)  
    if(!rst_n)
      wrState <= WR_BUF0;
    else 
      wrState <= wrState_n;
  always_comb begin
    wrState_n = wrState;
    buf0FullSet = 0;
    buf1FullSet = 0;
    case (wrState)
      WR_BUF0: begin
        wrBufSel = 0;
        if(switch) begin
          wrState_n = WR_BUF1;
          buf0FullSet = 1;
        end
      end WR_BUF1: begin
        wrBufSel = 1;
        if(switch) begin
          wrState_n = WR_BUF0;
          buf1FullSet = 1;
        end
      end
    endcase
  end

  typedef enum logic [1:0] {
    RD_IDLE,
    RD_BUF0,
    RD_BUF1
  } rdState_t;
  (* MARK_DEBUG="true" *)rdState_t rdState, rdState_n;
  always_ff @(posedge clk or negedge rst_n)  
    if(!rst_n)
      rdState <= RD_IDLE;
    else 
      rdState <= rdState_n;
  always_comb begin
    rdState_n = rdState;
    rdBufSel = 0; 
    rdStart = 0;
    buf0Full.reset = 0;
    buf1Full.reset = 0;
    case(rdState)
      RD_IDLE: begin
        if(buf0Full.value) begin
          rdState_n = RD_BUF0;
          rdStart = 1;
        end
        if(buf1Full.value) begin
          rdState_n = RD_BUF1;
          rdStart = 1;
        end
      end RD_BUF0: begin
        rdBufSel = 0; 
        if(rdDone) begin
          buf0Full.reset = 1;
          rdState_n = RD_IDLE;
        end
      end RD_BUF1: begin
        rdBufSel = 1; 
        if(rdDone) begin
          buf1Full.reset = 1;
          rdState_n = RD_IDLE;
        end
      end
    endcase
  end
endmodule

module RdAddrGen #(
    parameter WIDTH = 1920
  ) (
    clk, rst_n,
    start, done, valid,
    addr
);
  localparam ADDR_W = $clog2(WIDTH) + 3;

  input logic clk, rst_n; 
  input logic start;
  output logic done, valid;
  output logic [ADDR_W-1:0] addr;

  typedef struct {
    logic [2:0] nub;
    logic update;
    logic eq;
  } Cnt_t;

  Cnt_t col, row;
  logic zero;

  always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      col.nub <= 0;
    end else if (zero | col.eq) begin 
      col.nub <= 0;
    end else if (col.update) begin 
      col.nub <= (col.nub > 3)? ~col.nub+1 : ~col.nub;
    end
  end
  assign col.eq = col.nub == 4; 

  always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      row.nub <= 0;
    end else if (zero | row.eq) begin 
      row.nub <= 0;
    end else if (row.update) begin 
      row.nub <= (row.nub > 3)? ~row.nub+1 : ~row.nub;
    end
  end
  assign row.eq = row.nub == 4 && col.eq; 
  assign row.update = col.eq;

  typedef struct {
    logic [$clog2(WIDTH):0] nub;
    logic update;
    logic eq;
  } mcu_t;

  mcu_t mcu;
  always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      mcu.nub <= 0;
    end else if (zero) begin 
      mcu.nub <= 0;
    end else if (mcu.update) begin 
        mcu.nub <= mcu.nub + 8;
    end
  end
  assign mcu.eq = mcu.nub == WIDTH - 8 && row.eq; 
  assign mcu.update = row.eq;
  logic [$clog2(WIDTH)-1:0] colAddr;
  assign colAddr = mcu.nub + col.nub;
  assign addr = {row.nub, colAddr};

  typedef enum logic [1:0] {
    IDLE,
    SCAN,
    DONE
  } state_t;

  state_t state, state_n;
  always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n)
      state <= IDLE;
    else
      state <= state_n;
  end
  always_comb begin
    state_n = state;
    col.update = 0;
    zero = 0;
    valid = 0;
    done = 0;
    case(state)
      IDLE: begin
        if(start) begin
          state_n = SCAN;
        end
      end SCAN: begin
        valid = 1;
        if(mcu.eq & col.eq) begin
            zero = 1;
          if(!start) begin
            state_n = DONE;
          end else begin
            done = 1;
          end
        end else begin
          col.update = 1;
        end
      end DONE: begin
        done = 1;
        state_n = IDLE;
      end
    endcase
  end
endmodule

