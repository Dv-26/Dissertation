module Pe_tb;
  
  parameter DATA_WIDTH = 8;

  logic                   clk;
  logic                   rst_n;
  logic [DATA_WIDTH-1:0]  xIn;
  logic [DATA_WIDTH-1:0]  xDelayIn;
  logic [DATA_WIDTH-1:0]  zIn;
  logic [DATA_WIDTH-1:0]  CoefficientIn;
  logic [DATA_WIDTH-1:0]  xOut;
  logic [DATA_WIDTH-1:0]  xDelayOut;
  logic [DATA_WIDTH-1:0]  zOut;
  logic [DATA_WIDTH-1:0]  CoefficientOut;
  logic                   sumDiffSelIn;
  logic                   loadIn;
  logic                   sumDiffSelOut;
  logic                   loadOut;

  always #5 clk = ~clk;

  Pe#(.DATA_WIDTH(8)) pe_tb (
    .clk            (clk),
    .rst_n          (rst_n),
    .xIn            (xIn),
    .xDelayIn       (xDelayIn),
    .zIn            (zIn),
    .CoefficientIn  (CoefficientIn),
    .xOut           (xOut),
    .xDelayOut      (xDelayOut),
    .zOut           (zOut),
    .CoefficientOut (CoefficientOut),
    .sumDiffSelIn   (sumDiffSelIn),
    .loadIn         (loadIn),
    .sumDiffSelOut  (sumDiffSelOut),
    .loadOut        (loadOut)
  );

  always_ff @(posedge clk)
    xDelayIn <= xOut;

  int i;
  initial begin
    clk = 1;
    //xIn = 0;
    zIn = 0;
    //sumDiffSelIn = 0;
    //loadIn = 0;
    CoefficientIn = 1;
    for(i=0; i<8; i++)begin
      @(posedge clk)begin
        xIn <= i;
        sumDiffSelIn <= i%2;
        if(i == 0 || i == 1)
          loadIn <= 1;
        else
          loadIn <= 0;
        #10;
      end
    end
    @(posedge clk)
      sumDiffSelIn <= 0;
      loadIn = 0;
    #1000;
    $stop();
  end
endmodule
