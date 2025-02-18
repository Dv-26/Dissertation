  module Delay#(
    parameter DATA_WIDTH = 8,
    parameter DELAY = 5
  ) (
    input   logic clk,
    input   logic [DATA_WIDTH-1:0] in,
    output  logic [DATA_WIDTH-1:0] out
  );

    logic [DATA_WIDTH-1:0]  shiftReg[DELAY];
    generate
      genvar i; 
      for(i=0; i<DELAY; i++)begin  
        if(i==0)
          always_ff @(posedge clk)
            shiftReg[i] <= in;
        else
          always_ff @(posedge clk)
            shiftReg[i] <= shiftReg[i-1];
      end
    endgenerate

    assign out = shiftReg[DELAY-1];
  endmodule
