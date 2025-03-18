//`include "interface.sv"

module colortranf_tb ();

  localparam CLK_CYCLE = 5;

  logic clk, rst_n;
  dctPort_t in[3], out[3];

  RGB2YCbCr #(10) RGB2YCbCr(clk, rst_n, in, out);

  always #(CLK_CYCLE/2) clk = ~clk;
  
  int i;
  initial begin
    for (i=0; i<3; i++) begin
      in[i].data = 0;
      in[i].valid = 0;
    end
    clk = 1;
    rst_n = 0;
    #(5*CLK_CYCLE)
    rst_n = 1;
    #(5*CLK_CYCLE)
    @(negedge clk)
    for (i=0; i<3; i++) begin
      in[i].data = i * 40;
      in[i].valid = 1;
    end
    @(negedge clk)
    for (i=0; i<3; i++) begin
      in[i].valid = 0;
    end
    @(out[0].valid == 1)
    #(5*CLK_CYCLE);
    $stop();
  end

endmodule
