`include "interface.sv"
`include "uart.svh"

module top #(
  parameter WIDTH = 512,
  parameter HEIGHT = 512
) (
  input logic clk, rst_n,
  (* MARK_DEBUG="true" *) input logic rx,
  (* MARK_DEBUG="true" *) output logic tx
);
  (* MARK_DEBUG="true" *) logic exClk, inClk, sysRst_n;
  logic locked;
  clk_wiz_0 pll (
    .clk_out1(exClk),     // output clk_out1
    .clk_out2(),     // output clk_out2
    .reset(!rst_n), // input reset
    .locked(locked),       // output locked
    .clk_in1(clk)
  );

  assign sysRst_n = !(!locked & rst_n);
  UartIF uartRxPort();
  UartRx #(50000000, 115200) uartRx (exClk, sysRst_n, uartRxPort, rx);

  // (* MARK_DEBUG="true" *) dataPort_t coderIn;
  dataPort_t coderIn;
  Uart2coder #(WIDTH, HEIGHT) uart2coder (exClk, sysRst_n, uartRxPort, coderIn);

  (* MARK_DEBUG="true" *) huffman_pkg::HuffmanBus_t coderOut;
  // (* dont_touch = "true" *) huffman_pkg::HuffmanBus_t coderOut;
  JpegCoder #(WIDTH, HEIGHT, 12, 3) coder (exClk, exClk, sysRst_n, coderIn, coderOut);

  UartIF uartTxPort();
  Coder2uart coder2uart (exClk, exClk, sysRst_n, coderOut, uartTxPort);

  UartTx #(50000000, 115200) uartTx (exClk, sysRst_n, uartTxPort, tx);

endmodule
