`include "interface.sv"

module EntropyCoder #(
  parameter DATA_WIDTH = 10,
  parameter CHROMA = 0
) (clk, rst_n, in, out);
  import huffman_pkg::*;
  input logic clk, rst_n;
  input codePort_t in;
  output HuffmanBus_t out;

  tempCode_t temp2EOBgen, EOBgen2temp;
  tempCoder #(DATA_WIDTH) temp (
    clk, rst_n,
    in, temp2EOBgen
  );
  EOBgen #(DATA_WIDTH) EOBgenator (
    clk, rst_n,
    temp2EOBgen, EOBgen2temp
  );
  IndefiniteLengthCodeGen #(CHROMA) indefiniteLength (
    clk, rst_n,
    EOBgen2temp, out
  );
endmodule

module EOBgen #(
  parameter DATA_WIDTH = 10
) (
  input clk, rst_n,
  input huffman_pkg::tempCode_t  in,
  output huffman_pkg::tempCode_t  out
);
  import huffman_pkg::*;
  struct {tempCode_t current, next;} outReg;
  always_ff @(posedge clk or negedge rst_n)
    outReg.current <= !rst_n ? '0 : outReg.next;
  assign out = outReg.current;

  logic isZRL, notZRL, isEOB;
  assign isZRL = &{in.valid, !in.data.isDC, &in.data.run};
  assign notZRL = &{in.valid, !isZRL, !in.data.isDC};
  assign isEOB = &{in.done, !in.valid};
  logic bufRst;

  tempCode_t ZRLbuf;
  fifoWr_if #($bits(tempCode_t)) bufWr ();
  fifoRd_if #($bits(tempCode_t)) bufRd ();
  ShiftFIFO #($bits(tempCode_t), 4) InBuf (
    clk, rst_n,
    bufRst,
    bufWr, bufRd
  );
  assign bufWr.data = in;
  assign ZRLbuf = bufRd.data;

  logic outSel, outInvalid;
  struct {enum logic {NORMAL, RD_BUF} current, next;} state;
  always_ff @(posedge clk, negedge rst_n) 
    state.current <= !rst_n ? NORMAL : state.next;
  always_comb begin
    state.next = state.current;
    bufWr.en = 0;
    bufRd.en = 0;
    bufRst = 0;
    outSel = 0;
    outInvalid = 0;
    if(isZRL)
      bufWr.en = 1;
    case(state.current)
      NORMAL: begin
        if(isZRL)
          outInvalid = 1;
        if(isEOB)
          bufRst = 1;
        if(notZRL && !bufRd.empty) begin
          bufWr.en = 1;
          bufRd.en = 1;
          state.next = RD_BUF;
          outSel = 1;
        end
      end
      RD_BUF: begin
        outSel = 1;
        bufRd.en = 1;
        if(in.valid | isEOB)
          bufWr.en = 1;
        if(bufRd.empty) begin
          state.next = NORMAL;
          outSel = 0;
          bufRd.en = 0;
        end
      end
    endcase
  end

  always_comb begin
    outReg.next = in;
    if(outInvalid)
      outReg.next = '0;
    if(outSel)
      outReg.next = ZRLbuf;
    if(isEOB) begin
      outReg.next.valid = 1;
      outReg.next.data.run = 0;
      outReg.next.data.size = 0;
    end
  end
endmodule

module tempCoder #(
  parameter DATA_WIDTH = 10
) (
  input clk, rst_n,
  input codePort_t in,
  output huffman_pkg::tempCode_t out
);
  import huffman_pkg::*;
  typedef struct {
    logic [5:0] value;
    logic add, zero, eq;
  } cnt_t;

  typedef struct {
    logic [DATA_WIDTH-1:0] data;
    logic load, reset;
  } reg_t;

  typedef enum logic{
    DC,
    AC
  } state_t;
  state_t state, state_n;
  logic valid_n;

  always_ff @(posedge clk or negedge rst_n) begin
    state <= !rst_n? DC : state_n;
    out.valid <= !rst_n? 1'b0 : valid_n;
  end

  always_comb begin
    state_n = state;
    lastDC.load = 0;
    lastDC.reset = 0;
    zeroCnt.add = 0;
    zeroCnt.zero = 0;
    valid_n = 0;
    case(state)
      DC: begin  
        if(in.valid) begin
          valid_n = 1;
          if(!in.eop)
            lastDC.load = 1;
          else
            lastDC.reset = 1;
          state_n = AC;
        end
      end
      AC: begin
        if(in.valid) begin
          if(in.data == 0) begin
            if(zeroCnt.eq) begin
              valid_n = 1;
              zeroCnt.zero = 1;
            end else begin
              zeroCnt.add = 1;
            end
          end else begin
            valid_n = 1;
            zeroCnt.zero = 1;
          end
        end

        if(in.done) begin
          zeroCnt.zero = 1;
          state_n = DC;
          if(!in.valid)
            valid_n = 0;
        end
      end
    endcase
  end

  cnt_t zeroCnt;
  always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) 
      zeroCnt.value <= '0;
    else if(zeroCnt.zero)
      zeroCnt.value <= '0;
    else if(zeroCnt.add)
      zeroCnt.value <= zeroCnt.value + 1;
  end
  assign zeroCnt.eq = zeroCnt.value == 15;

  reg_t lastDC;
  logic [DATA_WIDTH-1:0] dcDiff;
  always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      lastDC.data <= '0;
    end else begin
      if(lastDC.reset)
          lastDC.data <= '0;
      else if(lastDC.load)
          lastDC.data <= in.data;
    end
  end
  assign dcDiff = in.data - lastDC.data;

  logic [$clog2(DATA_WIDTH-1):0] size_n;
  logic [DATA_WIDTH-2:0] vli_n;
  VliCode #(DATA_WIDTH) vliCoder (
    state == DC ? dcDiff : in.data,
    vli_n, size_n
  );
  always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      out.data.vli <= '0;
      out.data.size <= '0;
      out.data.isDC <= 0;
      out.data.run <= '0;
      out.sop <= 1'b0;
      out.eop <= 1'b0;
    end else begin
      out.sop <= in.sop;
      out.eop <= in.eop;
      if(valid_n) begin
        out.data.isDC <= (state == DC);
        out.data.vli <= vli_n;
        out.data.size <= size_n;
        out.data.run <= zeroCnt.value[3:0];
      end
    end
  end
  always_ff @(posedge clk or negedge rst_n)
    out.done <= !rst_n ? 1'b0 : in.done;

endmodule

module VliCode #(
    parameter DATA_WIDTH = 10
) (
    input logic [DATA_WIDTH-1:0] in,
    output logic [DATA_WIDTH-2:0]  vli,
    output logic [$clog2(DATA_WIDTH-1):0]  size
);
  logic [DATA_WIDTH-2:0] hotOne, reverse, abs;
  always_comb begin
    if(in[DATA_WIDTH-1]) begin
      vli = in[DATA_WIDTH-2:0] - 1;
      abs = ~vli;
    end else begin
      vli = in[DATA_WIDTH-2:0];
      abs = vli;
    end
    for(int i=0; i<DATA_WIDTH-1; i++)
      reverse[i] = abs[DATA_WIDTH-2-i];
    reverse = (~reverse + 1) & reverse;
    for(int i=0; i<DATA_WIDTH-1; i++)
      hotOne[i] = reverse[DATA_WIDTH-2-i];
  end
  logic [$clog2(DATA_WIDTH-1)-1:0]  bin;
  encode #(DATA_WIDTH-1) hot2bin (hotOne, bin);
  assign size = |in[DATA_WIDTH-2:0] ? bin + 1 : 0;

endmodule

module encode #(parameter WIDTH = 10) (in, out);
  localparam OUT_W = $clog2(WIDTH);
  input logic [WIDTH-1 : 0] in;
  output logic [OUT_W-1 : 0] out;
  logic [OUT_W-1:0] temp1[WIDTH];
  logic [WIDTH-1:0] temp2[OUT_W];
  generate
    genvar i, j;
    for(i=0; i<WIDTH; i++)
      assign temp1[i] = in[i]? i : 1'b0;
    for(i=0; i<WIDTH; i++)
      for(j=0; j<OUT_W; j++)
        assign temp2[j][i] = temp1[i][j];
    for(i=0; i<OUT_W; i++)
      assign out[i] = | temp2[i];
  endgenerate
endmodule
