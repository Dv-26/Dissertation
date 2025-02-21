module Pe_tb;
  
  parameter DATA_WIDTH = 8;

  logic                   clk;
  logic                   rst_n;

  logic [DATA_WIDTH-1:0]  x;
  logic                                 sumDiffSel;
  logic                                 load;

  logic [DATA_WIDTH-1:0]  z;
  logic                                 valid;

  always #5 clk = ~clk;

  logic [DATA_WIDTH-1:0] coefficient[4] = {{'1}, {'1}, {'1}, {'1}} ;
  x2zArray#(8, 4) pe_tb (
    .clk(clk),
    .rst_n(rst_n),
    .coefficient(coefficient),
    .x(x),
    .sumDiffSel(sumDiffSel),
    .load(load),
    .z(z),
    .valid(valid)
   );

  int i,j;
  initial begin
    clk = 1;
    rst_n = 0;
    load = 0;
    #5
    rst_n = 1;
    #5;
    for(i=0; i<8; i++)begin
      for(j=0; j<8; j++)begin
        @(posedge clk)begin
          x <= j;
          sumDiffSel <= j%2;
          if(j == 0 || j == 1)
            load <= 1;
          else
            load <= 0;
          #10;
        end
      end
    end
    @(posedge clk)
      sumDiffSel <= 0;
      load <= 0;
    #1000;
    $stop();
  end
endmodule
