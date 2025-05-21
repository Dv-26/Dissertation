`timescale 1ns/1ns
module uart_tb();

  localparam CYCLE = 80;

  logic clk, rst_n, rx, tx;
  always #(CYCLE/2) clk = ~clk;
  initial begin
    clk = 1;
    rst_n = 0;
    #(10*CYCLE)
    rst_n = 1;
  end
  UartTop uart_tb(clk, rst_n, rx, tx);
  assign rx = tx;

endmodule
