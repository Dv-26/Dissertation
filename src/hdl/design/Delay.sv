  module Delay#(
    parameter DATA_WIDTH = 8,
    parameter DELAY = 5
  ) (
    input   logic clk,
    input   logic rst_n,
    input   logic [DATA_WIDTH-1:0] in,
    output  logic [DATA_WIDTH-1:0] out
  );

    logic [DATA_WIDTH-1:0]  shiftReg[DELAY];
    generate
      genvar i; 
      for(i=0; i<DELAY; i++)begin  
        if(i==0)
          always_ff @(posedge clk or negedge rst_n)begin
            if(!rst_n)
              shiftReg[i] <= '0;
            else
              shiftReg[i] <= in;
          end
        else
          always_ff @(posedge clk) begin
            if(!rst_n)
              shiftReg[i] <= '0;
            else
              shiftReg[i] <= shiftReg[i-1];
          end
      end
    endgenerate

    assign out = shiftReg[DELAY-1];
  endmodule

  module ShiftReg#(
    parameter DATA_WIDTH = 8,
    parameter DELAY = 5,
    parameter TIMING = 4
  ) (
    input   logic clk,
    input   logic rst_n,
    input   logic shift,
    input   logic [DATA_WIDTH-1:0] in,
    output  logic [DATA_WIDTH-1:0] out
  );
    logic zero;
    logic [$clog2(TIMING)-1:0] timer;
    always_ff @(posedge clk) begin
      if (shift && !zero) begin
        timer <= timer + 1;
      end else begin
        timer <= 0;
      end
    end
    assign zero = timer == TIMING-2;

    logic [DATA_WIDTH-1:0]  shiftReg[DELAY];
    generate
      genvar i; 
      for(i=0; i<DELAY; i++)begin  
          always_ff @(posedge clk or negedge rst_n)begin
            if(!rst_n)
              shiftReg[i] <= '0;
            else if (zero)
              shiftReg[i] <= (i == 0)? in : shiftReg[i-1];
          end
      end
    endgenerate

    assign out = shiftReg[DELAY-1];

  endmodule