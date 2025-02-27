// `include "../design/interface.sv"
module dct_tb;
  
  parameter DATA_WIDTH = 10;

  logic                   clk;
  logic                   rst_n;

  dctPort_t x, y;

  always #5 clk = ~clk;

jpegCode #(DATA_WIDTH)coder(clk, rst_n, x, y);

  int i,j;
  initial begin
    clk = 1;
    rst_n = 0;
    x.valid = 0;
    #5
    rst_n = 1;
    #5;
    for(i=0; i<8; i++)begin
      for(j=0; j<8; j++)begin
        @(posedge clk)begin
          x.data <= j*10;
          x.valid <= 1;
          #10;
        end
      end
    end
    @(posedge clk)
      x.valid <= 0;
    #1000;
    $stop();
  end
endmodule
