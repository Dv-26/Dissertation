module Pe_tb;
  
  parameter DATA_WIDTH = 8;

  logic                   clk;
  logic                   rst_n;

  logic [DATA_WIDTH-1:0]  x[1];
  logic                                 sumDiffSel[1];
  logic                                 load[1];

  logic [DATA_WIDTH-1:0]  z[1];
  logic                                 valid[1];

  always #5 clk = ~clk;

  array#(8, 1, 4) pe_tb (
    .clk(clk),
    .rst_n(rst_n),
    .x(x),
    .sumDiffSel(sumDiffSel),
    .load(load),
    .z(z),
    .valid(valid)
   );

  int i;
  initial begin
    clk = 1;
    rst_n = 0;
    load[0] = 0;
    #5
    rst_n = 1;
    #5;
    for(i=0; i<8; i++)begin
      @(posedge clk)begin
        x[0] <= i;
        sumDiffSel[0] <= i%2;
        if(i == 0 || i == 1)
          load[0] <= 1;
        else
          load[0] <= 0;
        #10;
      end
    end
    @(posedge clk)
      sumDiffSel[0] <= 0;
      load[0] <= 0;
    #1000;
    $stop();
  end
endmodule
