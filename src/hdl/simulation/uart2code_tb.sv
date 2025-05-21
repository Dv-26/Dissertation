`timescale 1ns/1ns
`include "entropyCoder.svh" 
`include "interface.sv"
`include "uart.svh"

module uart2coderTB(); 

  localparam CYCLE = 80;
  localparam WIDTH = 8;
  localparam HEIGHT = 8;

  logic pclk, rst_n;
  logic rx, tx;
  UartIF in();
  always #(CYCLE/4) pclk = ~pclk;

  UartTx #(50000000, 115200) uartTx (pclk, rst_n, in, rx);

  top #(WIDTH, HEIGHT) topTB (
    pclk, rst_n,
    rx, tx
  );

  logic [23:0]pixels[WIDTH*HEIGHT];
  initial begin
    $readmemh("/home/dv/jpeg/Dissertation/src/test/test_img.hex",pixels);
    pclk = 0;
    rst_n = 0;
    in.data = 0;
    in.valid = 0;
    #(10*CYCLE)
    rst_n = 1;
    #(10*CYCLE)

    wait(!tx)
    #(50*CYCLE);
    $stop();
  end

  int i, j = 0;
  always @(posedge pclk) begin
    if(rst_n && in.ready && i < WIDTH*HEIGHT) begin
      in.data <= pixels[i][(2-j)*8+:8]; 
      in.valid <= 1;
      if(j == 2)begin
        j = 0;
        i++;
      end else begin
        j++;
      end
    end else begin
      in.valid <= 0;
    end
  end
endmodule
