`include "/home/dv/Documents/Dissertation/src/hdl/design/interface.sv"

module Pe #(
  parameter DATA_WIDTH = 8
) (
  input logic clk,
  PeCol_if.rx coefficient colRx,
  PeCol_if.tx coefficient colTx,
  PeRow_if.rx coefficient rowRx,
  PeRow_if.tx coefficient rowTx
);

typedef struct {
  logic [DATA_WIDTH-1 : 0] x;
  logic sumDiffSel;
  logic load;
  logic [DATA_WIDTH-1:0] coefficient;
} pePort_t;

  pePort_t inDelay[2];
  always_ff @(posedge clk)begin
    inDelay[0].x <= rowRx.x;
    inDelay[0].sumDiffSel <= rowRx.sumDiffSel ;
    inDelay[0].load <= rowRx.load ;
    inDelay[0].coefficient <= colIn.coefficient  ;
    inDelay[1] <= inDelay[0];
  end

  assign rowTx.x = inDelay[1].x;
  assign rowTx.sumDiffSel = inDelay[1].sumDiffSel ;
  assign rowTx.load = inDelay[1].load;
  assign colTx.coefficient = inDelay[1].coefficient;

  logic [DATA_WIDTH-1 : 0]  sum, diff;
  assign sum = rowRx.x + inDelay[0];
  assign diff = inDelay[0].x - inDelay[1].x;
  logic [DATA_WIDTH-1 : 0]  product;
  assign product = colRx.coefficient * (inDelay[0].sumDiffSel? sum : diff);

  logic [DATA_WIDTH-1 : 0] delay2In, delay2Out, acc;
  Delay #(DATA_WIDTH, 2)delay2(clk, delay2in, delay2Out);
  assign delay2in = inDelay[0].load? product : acc;
  assign acc = product + delay2Out;

  logic outSel;
  Delay #(DATA_WIDTH, 6)delay6(clk, inDelay[0].load, outSel);
  assign rowTx.z = outSel? acc : rowRx.z;
  assign rowTx.valid = rowRx.valid | outSel;
endmodule

module array #(
  parameter DATA_WIDTH = 8,
  parameter ROW = 1,
  parameter COL = 4
) (
  input logic clk,

  input logic [DATA_WIDTH-1:0] x[ROW],
  input logic sumDiffSel[ROW],
  input logic load[ROW],

  output logic [DATA_WIDTH-1:0] z[ROW],
  output logic valid[ROW]
);
`include "/home/dv/Documents/Dissertation/src/hdl/design/interface.sv"

  PeRow_if portArrayRow[ROW+1][COL+1]();
  PeCol_if portArrayCol[ROW+1][COL+1]();

  generate
    genvar i,j;
    for(i=0; i<ROW; i++)begin
      assign portArrayRow[i][0].x = x[i];
      assign portArrayRow[i][0].z = {DATA_WIDTH{1'b0}};
      assign portArrayRow[i][0].sumDiffSel = sumDiffSel[i];
      assign portArrayRow[i][0].load = load[i];
      assign portArrayRow[i][0].valid = 1'b0;

      for(j=0; j<COL; j++)begin
        Pe #(DATA_WIDTH) pe (
          clk,
          portArrayCol[i][j],
          portArrayCol[i+1][j],
          portArrayRow[i][j],
          portArrayRow[i][j+1]
        );
        if(i==0)
          assign portArrayCol[i][j].coefficient = 1;
      end

      assign z[i] = portArrayRow[i][COL].z;
      assign valid[i] = portArrayRow[i][COL].valid;
    end
  endgenerate

endmodule
