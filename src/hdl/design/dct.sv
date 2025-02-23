//`include "design/interface.sv"

module dct #(
  parameter DATA_WIDTH = 8
) (
  input logic clk,
  input logic rst_n,

  input logic [DATA_WIDTH-1:0] x,
  input logic sumDiffSel,
  input logic load,

  output logic [DATA_WIDTH-1:0] y,
  output logic valid
);

  logic [DATA_WIDTH-1:0] coefficient[4];

  assign coefficient = {1, 1, 1, 1};
  logic [DATA_WIDTH-1:0] z;
  logic zValid;
  x2zArray #(DATA_WIDTH, 4) x2z (clk, rst_n, coefficient, x, sumDiffSel, load, z, zValid);

  logic sel;
  logic [DATA_WIDTH-1:0] delay8In, delay8Out, sumDiff;
  Delay #(DATA_WIDTH, 8)delay8(clk, delay8In, delay8Out);
  assign delay8In = sel? z : z-delay8Out;
  assign sumDiff = sel? delay8Out : delay8Out+z;

  logic zLoad;
  z2yArray #(DATA_WIDTH, 4) z2y (clk, rst_n, coefficient, sumDiff, load, y, valid);
endmodule

module x2zArray #(
  parameter DATA_WIDTH = 8,
  parameter COL = 4
) (
  input logic clk,
  input logic rst_n,

  input logic [DATA_WIDTH-1:0]  coefficient[COL],

  input logic [DATA_WIDTH-1:0] x,
  input logic sumDiffSel,
  input logic load,

  output logic [DATA_WIDTH-1:0] z,
  output logic valid
);

// verilator lint_off UNOPTFLAT
  x2zPort_t rowPort[COL+1]; 
// verilator lint_on UNOPTFLAT
  assign {rowPort[0].x.data, rowPort[0].x.sumDiffSel, rowPort[0].x.load} = {x, sumDiffSel, load}; 
  assign {rowPort[0].z.data, rowPort[0].z.valid} = '0;

  generate
    genvar i;
    for(i=0; i<COL; i++)begin

      x2zX_t xDelay2[2];
      always_ff @(posedge clk)begin
        xDelay2[0] <= rowPort[i].x; 
        xDelay2[1] <= xDelay2[0];
      end
      assign rowPort[i+1].x = xDelay2[1];

      logic [DATA_WIDTH-1:0] sum,diff;
      assign sum = rowPort[i].x.data + xDelay2[0].data;
      assign diff = xDelay2[0].data - xDelay2[1].data;
       
      logic [DATA_WIDTH-1:0] product;
      assign product = coefficient[i] * (xDelay2[0].sumDiffSel? diff : sum);

      logic [DATA_WIDTH-1 : 0] delay2In, delay2Out, acc;
      assign delay2In = xDelay2[0].load? product : acc;
      assign acc = product + delay2Out;
      Delay #(DATA_WIDTH, 2)delay2(clk, delay2In, delay2Out);

      logic outSel;
      Delay #(1, 6)delay6(clk, xDelay2[0].load, outSel);
      assign rowPort[i+1].z.data = outSel?  acc : rowPort[i].z.data;
      assign rowPort[i+1].z.valid = rowPort[i].z.valid | outSel;
    end
  endgenerate

  assign z = rowPort[COL].z.data;
  assign valid = rowPort[COL].z.valid;
endmodule

module z2yArray #(
  parameter DATA_WIDTH = 8,
  parameter COL = 4
) (
  input wire  clk,
  input wire  rst_n,
  input logic [DATA_WIDTH-1:0]  coefficient[COL],

  input logic [DATA_WIDTH-1:0] z,
  input logic load,

  output logic [DATA_WIDTH-1:0] y,
  output logic valid
);
// verilator lint_off UNOPTFLAT
  z2yPort_t rowPort[COL+1];
// verilator lint_on UNOPTFLAT
  assign {rowPort[0].z.data, rowPort[0].z.load} = {z, load};
  assign {rowPort[0].y.data, rowPort[0].y.valid} = '0;
  generate 
    genvar i;
    for (i=0; i<COL; i++) begin: pe
      Delay #(DATA_WIDTH+1, 16) rowDelay16 (
        clk,
        {rowPort[i].z.data, rowPort[i].z.load},
        {rowPort[i+1].z.data, rowPort[i+1].z.load}
      );

      logic [DATA_WIDTH-1 : 0] product, acc, delay16In, delay16Out;
      assign product = coefficient[i] * rowPort[i].z.data;
      assign acc = product + delay16Out;
      Delay #(DATA_WIDTH, 16) delay16 (clk, delay16In, delay16Out);
      assign delay16In = rowPort[i].z.load? product : acc;

      logic outSel;
      Delay #(1, 48) delay48 (clk, rowPort[i+1].z.load, outSel);
      assign rowPort[i+1].y.data = outSel? acc : rowPort[i].y.data;
      assign rowPort[i+1].y.valid = rowPort[i].y.valid | outSel;
    end
  endgenerate

  assign {y, valid} = {rowPort[COL].y.data, rowPort[COL].y.valid};

endmodule
