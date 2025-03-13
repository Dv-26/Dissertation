`include "interface.sv"
 
module Dct #(
  parameter DATA_WIDTH = 10,
  parameter ROW = 3
) (
  input logic clk, rst_n,
  input dctPort_t in[ROW],
  output dctPort_t out[ROW]
);

  dctPort_t x[ROW], z[ROW], y[ROW];
  rom_if #(DATA_WIDTH, 8) x2zCoe[4] ();
  rom_if #(DATA_WIDTH, 8) z2yCoe[4] ();

  genvar i;
  generate
    for (i=0; i<ROW; i++) begin
      if(i == 0) begin
        assign x[i] = in[i];
      end else begin
        Delay #(DATA_WIDTH+1, i) inDelay (
          clk, rst_n,
          {in[i].data, in[i].valid},
          {x[i].data, x[i].valid}
        );
      end
    end
  endgenerate

  coefficientMap #(DATA_WIDTH, 8) coefficientMap (x2zCoe, z2yCoe);
  Array #(DATA_WIDTH, 2, 4, ROW) x2zArray (clk, rst_n, x2zCoe, x, z);
  Array #(DATA_WIDTH, 16, 4, ROW) z2yArray (clk, rst_n, z2yCoe, z, y);

  assign out = y;
endmodule

module Array #(
  parameter DATA_WIDTH = 10,
  parameter LENGHT = 2,
  parameter COL = 4,
  parameter ROW = 1
) (
  input logic clk, rst_n,
  rom_if.rx coe[COL],
  input dctPort_t in[ROW],
  output dctPort_t out[ROW]
);

localparam CNT_WIDTH = $clog2(LENGHT*COL);

genvar i,j;
generate

  peColPort_t colPorts[ROW+1][COL];
  peRowPort_t rowPorts[ROW][COL+1];
  logic validDelay[COL];

  for(i=0; i<ROW; i++) begin: row
      logic [CNT_WIDTH-1:0] cnt;
      logic cntAdd;
      always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n)begin
          cnt <= '0;
        end else if(cntAdd) begin
          cnt <= cnt + 1;
        end
      end
      assign cntAdd = in[i].valid;

      logic [DATA_WIDTH-1:0] sumDiff, sum, diff, diffRegIn, diffRegOut;
      logic sumDiffSel, peLoad;
      Delay #(DATA_WIDTH, LENGHT/2) diffReg (clk, rst_n, diffRegIn, diffRegOut); 
      assign diff = diffRegOut -in[i].data;
      assign sum = in[i].data + diffRegOut;
      assign sumDiffSel = cnt[$clog2(LENGHT)-1] & in[i].valid;
      assign diffRegIn = sumDiffSel? diff : in[i].data;
      assign sumDiff = sumDiffSel? sum : diffRegOut;

      if (i==0) begin
        Delay #(2, LENGHT/2) loadDelay (
          clk, rst_n,
          {~|cnt[CNT_WIDTH-1:$clog2(LENGHT)] & in[i].valid, in[i].valid},
          {peLoad, validDelay[0]}
        );
      end else begin
        Delay #(1, LENGHT/2) loadDelay (
          clk, rst_n,
          ~|cnt[CNT_WIDTH-1:$clog2(LENGHT)] & in[i].valid,
          peLoad
        );
      end

      assign {rowPorts[i][0].in.data, rowPorts[i][0].in.load} = {sumDiff, peLoad};
      assign {rowPorts[i][0].result.data, rowPorts[i][0].result.valid} = {'0, '0};

      for(j=0; j<COL; j++)begin : col

        if(i == 0)begin
          assign colPorts[0][j].data = coe[j].data;
          logic [CNT_WIDTH-1:0] cnt;
          logic cntAdd;
          always @(posedge clk or negedge rst_n) begin
            if(!rst_n) begin
              cnt <= 0;
            end else if (cntAdd) begin
              cnt <= cnt + 1;
            end
          end
          assign cntAdd = validDelay[j];
          assign coe[j].en = validDelay[j];
          assign coe[j].addr = (cnt >> $clog2(LENGHT)-1);
          if(j != 0) begin
            Delay #(1, LENGHT) validShift (clk, rst_n, validDelay[j-1], validDelay[j]);
          end
        end

        Pe #(DATA_WIDTH, LENGHT, COL) pe (
          clk, rst_n,
          rowPorts[i][j],
          rowPorts[i][j+1],
          colPorts[i][j],
          colPorts[i+1][j]
        );
      end
      assign out[i].data = rowPorts[i][COL].result.data;
      assign out[i].valid = rowPorts[i][COL].result.valid;
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

  Delay #(DATA_WIDTH, 1) colDelay (clk, rst_n, colIn.data, colOut.data);

  logic [DATA_WIDTH-1:0] product;
  multiplier #(DATA_WIDTH, DATA_WIDTH) multiplier (colIn.data, rowIn.in.data, product);
  
  logic [DATA_WIDTH-1:0] accDelayIn, accDelayOut, acc;
  Delay #(DATA_WIDTH+1, LENGHT) accDelay (clk, rst_n, accDelayIn, accDelayOut);
  assign acc = accDelayOut + product;
  assign accDelayIn = rowIn.in.load? product : acc;

  logic resultSel;
  generate
    if(ACC_NUB > 2)begin
      Delay #(1, LENGHT*(ACC_NUB-2)) loadDelay (clk, rst_n, rowOut.in.load, resultSel);
    end else begin
      assign resultSel = rowOut.in.load;
    end
  endgenerate

  assign rowOut.result.data = resultSel? acc : rowIn.result.data;
  assign rowOut.result.valid = resultSel | rowIn.result.valid;
endmodule

module multiplier #(
  parameter   DATA_WIDTH = 8,
  parameter   SHIFT = 8
) (
  input signed [DATA_WIDTH-1:0] coefficient,
  input signed [DATA_WIDTH-1:0] in,
  output signed [DATA_WIDTH-1:0]  out
);

  logic signed [2*DATA_WIDTH-1 : 0] product;
  assign product = coefficient * in;
  assign out = (product + 2**(SHIFT-1)) >>> SHIFT;
endmodule

module coefficientMap #(
  parameter DATA_WIDTH = 8,
  parameter DEPTH = 8,
  parameter COL = 4
) (
  rom_if.tx a[4],
  rom_if.tx b[4]
);

  reg [DATA_WIDTH-1:0]  memoryArray[DEPTH][4];
  generate
    genvar i;
    for(i=0; i<COL; i++) begin
      assign a[i].data = a[i].en? memoryArray[a[i].addr][i] : '0;
      assign b[i].data = b[i].en? memoryArray[b[i].addr][i] : '0;
    end
  endgenerate

  localparam real PI = 3.14159265358979323846;  // Define π manually
  logic signed [DATA_WIDTH-1:0] cos[7];
  int n;
  initial begin
    for(n=0; n<7; n++)begin
      if(n == 0)
        cos[n] = $cos(4*PI / 16) * 2**(DATA_WIDTH-1);
      else
        cos[n] = $cos(n*PI / 16) * 2**(DATA_WIDTH-1);
    end
    memoryArray[0] = {cos[0], cos[2], cos[0], cos[5]};
    memoryArray[1] = {cos[1], cos[3], cos[4], cos[6]};
    memoryArray[2] = {cos[0], cos[5], -1*cos[0], -1*cos[2]};
    memoryArray[3] = {cos[3], -1*cos[6], -1*cos[1], -1*cos[4]};
    memoryArray[4] = {cos[0], -1*cos[5], -1*cos[0], cos[2]};
    memoryArray[5] = {cos[4], -1*cos[1], cos[6], cos[3]};
    memoryArray[6] = {cos[0], -1*cos[2], cos[0], -1*cos[5]};
    memoryArray[7] = {cos[6], -1*cos[4], cos[3], -1*cos[1]};
  end
endmodule
