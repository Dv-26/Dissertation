`include "interface.sv"
 
module Array #(
  parameter DATA_WIDTH = 10,
  parameter LENGHT = 2,
  parameter COL = 4,
  parameter ROW = 4
) (
  input logic clk, rst_n,
  input logic [DATA_WIDTH-1:0] coefficient[COL];
  input dctPort_t in[ROW],
  input dctPort_t out[ROW]
);
genvar i,j;

generate

peColPort_t colPorts[ROW+1][COL];
peRowPort_t rowPorts[ROW][COL+1];

for(i=0; i<ROW; i++) begin
    logic [2:0] cnt8;
    always_ff @(posedge clk or negedge rst_n) begin
      if(!rst_n)begin
        cnt8 <= '0;
      end else if(in[i].valid) begin
        cnt8 <= cnt8 + 1;
      end
    end

    logic [DATA_WIDTH-1:0] sumDiff, sum, diff, diffRegIn, diffRegOut;
    logic sumDiffSel, peLoad;
    Delay #(DATA_WIDTH, LENGHT/2) diffReg (clk, rst_n, diffRegIn, diffRegOut); 
    assign diff = in[i].data - diffRegOut;
    assign sum = in[i].data + diffRegOut;
    assign sumDiffSel = cnt[0] & in[i].valid;
    assign diffRegIn = sumDiffSel? diff : in[i].data;
    assign sumDiff = sumDiff? diff : sum;
    Delay #(1, 1) loadDelay #(
      clk, rst_n,
      ~|cnt[2:0] & in[i].valid,
      peLoad
    );

    assign {rowPorts[0].in.data, rowPorts[0].in.load} = {sumDiff, peLoad};
    assign {rowPorts[0].result.data, rowPorts[0].result.valid} = {'0, '0};
    for(j=0; j<COL; j++)begin
      if(i == 0)
        assign colPorts[0][j].data = coefficient[j];
      Pe #(DATA_WIDTH, 2, 4) pe (
        clk, rst_n,
        rowPorts[i][j],
        rowPorts[i][j+1],
        colPorts[i][j],
        colPorts[i+1][j]
      );
    end
    assign out[i].data = rowPorts[i][COL+1].result.data;
    assign out[i].valid = rowPorts[i][COL+1].result.valid;
end
endgenerate

endmodule 

module Pe #(
    parameter DATA_WIDTH = 10,
    parameter LENGHT = 2,
    parameter ACC_NUB = 4
) (
    input logic clk, rst_n,

    input peRowPort_t rowIn,
    output peRowPort_t rowOut,

    input peColPort_t colIn,
    output peColPort_t colOut
);

  Delay #(DATA_WIDTH+1, LENGHT) rowDelay (
    clk, rst_n,
    {rowIn.in.data,  rowIn.in.load},
    {rowOut.in.data, rowOut.in.load}
  );

  Delay #(DATA_WIDTH, LENGHT) colDelay (clk, rst_n, colIn.data, colOut.data);

  logic [DATA_WIDTH-1:0] product;
  multiplier #(DATA_WIDTH, DATA_WIDTH) multiplier (colIn.data, rowIn.in.data, product);

  logic [DATA_WIDTH-1:0] accDelayIn, accDelayOut, acc;
  Delay #(DATA_WIDTH+1, LENGHT) accDelay (clk, rst_n, accDelayIn, accDelayOut);
  assign acc = accDelayOut + product;
  assign accDelayIn = rowIn.in.load? product : acc;

  logic resultSel;
  generate
    if(ACC_NUB > 1)begin
      Delay #(1, LENGHT*(ACC_NUB-1)) loadDelay (clk, rst_n, rowOut.in.load, resultSel);
    end else begin
      assign resultSel = rowOut.in.load;
    end
  endgenerate

  assign rowOut.result.data = resultSel? acc : rowIn.result.data;
  assign rowOut.result.valid = resultSel | rowIn.result.valid;
endmodule

