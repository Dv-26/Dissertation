`include "interface.sv"
`include "entropyCoder.svh"

module EntropyCoder #(
  parameter DATA_WIDTH = 10
) (
  input clk, rst_n,
  input codePort_t in,
  output logic [$bits(tempCode_t)-1:0] out
);
  tempCode_t temp2EOBgen, EOBgen2temp;
  tempCoder #(DATA_WIDTH) temp (clk, rst_n, in, temp2EOBgen);
  EOBgen #(DATA_WIDTH) EOBgenator (clk, rst_n, temp2EOBgen, EOBgen2temp);
  assign out = EOBgen2temp;
endmodule

module EOBgen #(
  parameter DATA_WIDTH = 10
) (
  input clk, rst_n,
  input tempCode_t  in,
  output tempCode_t  out
);
  tempCode_t out_n;
  always_ff @(posedge clk or negedge rst_n)
    out <= !rst_n ? '0 : out_n ;

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
  enum logic {NORMAL, RD_BUF} state, state_n;
  always_ff @(posedge clk, negedge rst_n) 
    state <= !rst_n ? NORMAL : state_n;
  always_comb begin
    state_n = state;
    bufWr.en = 0;
    bufRd.en = 0;
    bufRst = 0;
    outSel = 0;
    outInvalid = 0;
    if(isZRL)
      bufWr.en = 1;
    case(state)
      NORMAL: begin
        if(isZRL)
          outInvalid = 1;
        if(isEOB)
          bufRst = 1;
        if(notZRL && !bufRd.empty) begin
          bufWr.en = 1;
          bufRd.en = 1;
          state_n = RD_BUF;
          outSel = 1;
        end
      end
      RD_BUF: begin
        outSel = 1;
        bufRd.en = 1;
        if(in.valid | isEOB)
          bufWr.en = 1;
        if(bufRd.empty) begin
          state_n = NORMAL;
          outSel = 0;
          bufRd.en = 0;
        end
      end
    endcase
  end

  assign out_n = outSel ? ZRLbuf : outInvalid ? '0 : in;
endmodule

module tempCoder #(
  parameter DATA_WIDTH = 10
) (
  input clk, rst_n,
  input codePort_t in,
  output tempCode_t out
);
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
          lastDC.load = 1;
          state_n = AC;
        end
      end AC: begin
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
    end else if(valid_n) begin
      out.data.isDC <= (state == DC);
      out.data.vli <= vli_n;
      out.data.size <= size_n;
      out.data.run <= zeroCnt.value[3:0];
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
