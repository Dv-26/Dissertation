//`include "interface.sv"
module dct_tb;
  
  parameter DATA_WIDTH = 10;
  parameter LENGHT = 2;
  parameter COL = 4;
  parameter ROW = 3;

  logic                   clk;
  logic                   rst_n;

  always #5 clk = ~clk;

  dctPort_t stimulate, in[ROW], out[ROW];
  JpegCode #(DATA_WIDTH, ROW) coder (
    clk, rst_n,
    in,
    out
  );

  generate
  genvar n;
    for(n=0; n<ROW; n++)
      assign in[n] = stimulate;
  endgenerate

  int i,j;
  initial begin
    clk = 1;
    rst_n = 0;
    stimulate.valid = 0;
    #5
    rst_n = 1;
    #5;
    for(i=0; i<8; i++)begin
      for(j=0; j<8; j++)begin
        @(posedge clk)begin
          stimulate.data <= j*10;
          stimulate.valid <= 1;
          #10;
        end
      end
    end
    @(posedge clk)
      stimulate.valid <= 0;
    #1000;
    $stop();
  end
endmodule
