`timescale 1ns/1ns
//`include "interface.sv"
`define __SIM__
module code_tb;
   
  localparam CYCLE = 80;
  localparam WIDTH = 512;
  localparam HEIGHT = 512;

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

  huffman_pkg::HuffmanBus_t out;
  top #(WIDTH, HEIGHT) top_tb (
    clk, rst_n,
    pclk, vsync, href, data,
    out
  );
  logic [23:0]pixels[WIDTH*HEIGHT];
  int i, j;

  initial begin
    $readmemh("/home/dv/jpeg/Dissertation/src/test/test_img.hex",pixels);
    clk = 1;
    pclk = 1;
    href = 0;
    vsync = 0; 
    rst_n = 0;
    #(2*CYCLE);
    rst_n = 1;
    #(2*CYCLE);
    repeat (1) begin
      @(negedge pclk)
        vsync = 1; 
      #TIME_2;
      vsync = 0; 
      #TIME_3;
      for(i =0; i<HEIGHT; i++)begin
        href = 1;
        for(j=0; j<WIDTH; j++) begin
          logic [15:0] rgb565;
          logic [7:0] r, g, b;
          {r, g, b} = pixels[i*WIDTH + j];
          rgb565 = {r[7:3], g[7:2], b[7:3]};
          @(negedge pclk)
            data <= r;
          @(negedge pclk)
            data <= g;
          @(negedge pclk)
            data <= b;
        end
        @(negedge pclk)
        data <= 'x;
        href <= 0;
        #TIME_7;
      end
      #(TIME_5 - TIME_7);
    end

    wait(out.done)
    #(TIME_5 - TIME_7);
    $stop();
  end

  integer file; 
  initial begin
      file=$fopen("/home/dv/jpeg/Dissertation/src/test/jpeg_stream.bin", "wb");   
      if(file == 0) 
        $error("Failed to open file");
  end
  always @(posedge clk or negedge rst_n) begin
    if(out.valid) begin
      for(int i=0; i<out.data.size; i+=8)begin
        logic [7:0] byte_val = out.data.code[8*(7-i/8)+:8];
        $fwrite(file, "%c", byte_val);
      end
      if(out.done) begin
        $fclose(file);
        $display("Raw JPEG data saved");
      end
    end
  end

endmodule
