`include "./interface.sv"

module dct #(
  parameter DATA_WIDTH = 8
) (
  input logic clk,
  input logic rst_n,

  input logic [DATA_WIDTH-1:0] x,
  input logic sumDiffSel,
  input logic load,

  output logic [DATA_WIDTH-1:0] sumDiff,
  input logic sel
);

  logic [DATA_WIDTH-1:0] z;
  logic [DATA_WIDTH-1:0] zValid;
  x2zArray #(DATA_WIDTH, 4 ) x2z (clk, rst_n, x, sumDiffSel, load, z, zValid);

  logic [DATA_WIDTH-1:0] delay8In, delay8Out;
  Delay #(DATA_WIDTH, 8)delay8(clk, delay8In, delay8Out);
  assign delay8In = sel? z : z-delay8Out;
  assign sumDiff = sel? delay8Out : delay8Out+z;

endmodule

module x2zPe #(
  parameter DATA_WIDTH = 8
) (
  input logic clk,
  input logic rst_n,
  PeCol_if.rx colRx,
  PeCol_if.tx colTx,
  X2zPeRow_if.rx rowRx,
  X2zPeRow_if.tx rowTx
);

typedef struct {
  logic [DATA_WIDTH-1 : 0] x;
  logic sumDiffSel;
  logic load;
  logic [DATA_WIDTH-1:0] coefficient;
} pePort_t;

  pePort_t inDelay[2];
  always_ff @(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
      inDelay[0].x <= 0;
      inDelay[0].sumDiffSel <=  0;
      inDelay[0].load <= 0;
      inDelay[0].coefficient <=  0;
      inDelay[1].x <= 0;
      inDelay[1].sumDiffSel <=  0;
      inDelay[1].load <= 0;
      inDelay[1].coefficient <=  0;
    end else begin
      inDelay[0].x <= rowRx.x;
      inDelay[0].sumDiffSel <= rowRx.sumDiffSel ;
      inDelay[0].load <= rowRx.load ;
      inDelay[0].coefficient <= colRx.coefficient  ;
      inDelay[1] <= inDelay[0];
    end
  end

  assign rowTx.x = inDelay[1].x;
  assign rowTx.sumDiffSel = inDelay[1].sumDiffSel ;
  assign rowTx.load = inDelay[1].load;
  assign colTx.coefficient = inDelay[0].coefficient;

  logic [DATA_WIDTH-1 : 0]  sum, diff;
  assign sum = rowRx.x + inDelay[0].x;
  assign diff = inDelay[0].x - inDelay[1].x;
  logic [DATA_WIDTH-1 : 0]  product;
  assign product = colRx.coefficient * (inDelay[0].sumDiffSel? diff : sum);

  logic [DATA_WIDTH-1 : 0] delay2In, delay2Out, acc;
  assign delay2In = inDelay[0].load? product : acc;
  assign acc = product + delay2Out;
  Delay #(DATA_WIDTH, 2)delay2(clk, delay2In, delay2Out);

  logic outSel;
  Delay #(1, 6)delay6(clk, inDelay[0].load, outSel);
  assign rowTx.z = outSel? acc : rowRx.z;
  assign rowTx.valid = rowRx.valid | outSel;
endmodule

module x2zArray #(
  parameter DATA_WIDTH = 8,
  parameter COL = 4
) (
  input logic clk,
  input logic rst_n,

  input logic [DATA_WIDTH-1:0] x,
  input logic sumDiffSel,
  input logic load,

  output logic [DATA_WIDTH-1:0] z,
  output logic valid
);
`include "interface.sv"

  X2zPeRow_if portArrayRow[COL+1]();
  PeCol_if portArrayCol[2][COL]();

  assign portArrayRow[0].x = x;
  assign portArrayRow[0].z = {DATA_WIDTH{1'b0}};
  assign portArrayRow[0].sumDiffSel = sumDiffSel;
  assign portArrayRow[0].load = load;
  assign portArrayRow[0].valid = 1'b0;

  generate
    genvar i;
    for(i=0; i<COL; i++)begin
      x2zPe #(DATA_WIDTH) pe (
        clk,
        rst_n,
        portArrayCol[0][i],
        portArrayCol[1][i],
        portArrayRow[i],
        portArrayRow[i+1]
      );
    assign portArrayCol[0][i].coefficient = 1;
    end
  endgenerate

  assign z = portArrayRow[COL].z;
  assign valid = portArrayRow[COL].valid;
endmodule

module z2yPe #(
  parameter DATA_WIDTH = 8
) (
  input wire  clk,
  input wire  rst_n,
  PeCol_if.rx colRx,
  Z2yPeRow_if.rx rowRx,
  Z2yPeRow_if.tx rowTx
);

  logic [DATA_WIDTH-1 : 0] product, acc, delay16In, delay16Out;
  assign product = colRx.coefficient * rowRx.z;
  assign acc = delay16Out + product;
  Delay #(DATA_WIDTH, 16) delay16 (clk, delay16In, delay16Out);
  assign delay16In = rowRx.load? product : acc;

  logic outSel;
  Delay #(1, 64) delay64 (clk, rowRx.load, outSel);
  assign rowTx.y = outSel? acc : rowRx.y;

  Delay #(DATA_WIDTH+1, 16) rowDelay16 (
    clk,
    {rowRx.z, rowRx.load},
    {rowTx.z, rowTx.load}
  );

endmodule