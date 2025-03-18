`timescale 1ns/1ns
//`include "interface.sv"
module code_tb;
   
  localparam CYCLE = 80;
  localparam WIDTH = 24;
  localparam HEIGHT = 16;

  localparam TIME_2 = 5 * 2 * CYCLE;
  localparam TIME_3 = 10  * 2 * CYCLE;
  localparam TIME_6 = WIDTH * 2 * CYCLE;
  localparam TIME_7 = 5 * 2 * CYCLE;
  localparam TIME_5 = 10 * 2 * CYCLE;

  logic pclk, clk, rst_n;
  logic vsync, href;
  logic [7:0] data;

  always #(CYCLE/2) clk = ~clk;
  always #(CYCLE/4) pclk = ~pclk;

  dctPort_t out[3]; 
  top #(WIDTH, HEIGHT) top_tb (
    clk, rst_n,
    pclk, vsync, href, data,
    out
  );
  int i, j;

  initial begin
    clk = 1;
    pclk = 1;
    href = 0;
    vsync = 0; 
    rst_n = 0;
    #(2*CYCLE);
    rst_n = 1;
    #(2*CYCLE);
    @(negedge pclk)
      vsync = 1; 
    #TIME_2;
    vsync = 0; 
    #TIME_3;
    for(i =0; i<HEIGHT; i++)begin
      href = 1;
      for(j=0; j<WIDTH; j++) begin
        @(negedge pclk)
          data <= 1;
        @(negedge pclk)
          data <= 2; 
      end
      @(negedge pclk)
      data <= 'x;
      href <= 0;
      #TIME_7;
    end
    #(TIME_5 - TIME_7)
    $stop();
  end
  

endmodule
