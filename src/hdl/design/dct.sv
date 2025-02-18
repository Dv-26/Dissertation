module Pe
#(
  parameter DATA_WIDTH = 8
)(
  input   logic                   clk,
  input   logic                   rst_n,

  input   logic [DATA_WIDTH-1:0]  xIn,
  input   logic [DATA_WIDTH-1:0]  xDelayIn,
  input   logic [DATA_WIDTH-1:0]  zIn,
  input   logic [DATA_WIDTH-1:0]  CoefficientIn,

  output  logic [DATA_WIDTH-1:0]  xOut,
  output  logic [DATA_WIDTH-1:0]  xDelayOut,
  output  logic [DATA_WIDTH-1:0]  zOut,
  output  logic [DATA_WIDTH-1:0]  CoefficientOut,

  input   logic                   sumDiffSelIn,
  input   logic                   loadIn,

  output  logic                   sumDiffSelOut,
  output  logic                   loadOut
);

  logic [DATA_WIDTH-1:0] xDelay;
  always_ff @(posedge clk)
    xDelay <= xIn;

  logic [DATA_WIDTH-1:0] sum, diff;
  assign sum = xIn + xDelay;
  assign diff = xDelay - xDelayIn;

  logic [DATA_WIDTH-1:0]  product;
  logic sumDiffSel;
  always_ff @(posedge clk)
    sumDiffSel <= sumDiffSelIn;
  
  assign product = CoefficientIn * (sumDiffSel? diff : sum);

  logic [DATA_WIDTH-1:0] DelayIn, DelayOut, accumulate;
  logic load;
  assign accumulate = product + DelayOut;
  always_ff @(posedge clk)
    load <= loadIn;
  assign DelayIn = load? product : accumulate;
  Delay #(DATA_WIDTH, 2)Delay_2(clk, DelayIn, DelayOut); 

  logic outSel;
  Delay #(1, 6)Delay_7(clk, load, outSel); 

  always_ff @(posedge clk)
    CoefficientOut <= CoefficientIn;


  assign sumDiffSelOut = sumDiffSel;
  assign loadOut = load;
  assign zOut = outSel? accumulate : zIn;
  assign xOut = xDelay;
  assign xDelayOut = xDelay;

endmodule


