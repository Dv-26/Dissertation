`include "interface.sv"

typedef struct packed {
  logic [11:0] data;
  logic sop, eop;
  logic load;
} in_t;

typedef struct {
  logic [11:0] data;
  logic sop, eop;
  logic sumDiffSel;
  logic load;
} x2zX_t;

typedef struct packed {
  logic [11:0] data;
  logic sop, eop;
  logic valid;
} result_t;

typedef struct packed {
  in_t in;
  result_t result;
} peRowPort_t;

typedef struct {
  logic [11:0] data;
}peColPort_t;

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
        Delay #($bits(dctPort_t), i) inDelay (clk, rst_n, in[i], x[i]);
      end
    end

    for (i=0; i<4; i++) begin
      coefficientMap #(DATA_WIDTH, i) coefficientMapX2z (clk, x2zCoe[i]);
      coefficientMap #(DATA_WIDTH, i) coefficientMapZ2y (clk, z2yCoe[i]);
    end
  endgenerate

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

generate
  genvar i,j;
  peColPort_t colPorts[ROW+1][COL];
  peRowPort_t rowPorts[ROW][COL+1];
  logic validDelay[COL];

  for(i=0; i<ROW; i++) begin: row

    sumDiffGen #(LENGHT, COL) sumDiffGen (
      clk, rst_n,
      in[i], rowPorts[i][0].in
    );
    // assign {rowPorts[i][0].result.data, rowPorts[i][0].result.valid} = {'0, '0};
    assign rowPorts[i][0].result = '0;
    if (i==0)
      Delay #(1, LENGHT/2) loadDelay ( clk, rst_n, in[i].valid, validDelay[0]);

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
    assign out[i] = rowPorts[i][COL];
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

  Delay #($bits(in_t)-1, LENGHT) rowDelay (
    clk, rst_n,
    {rowIn.in.data, rowIn.in.eop, rowIn.in.load},
    {rowOut.in.data, rowOut.in.eop, rowOut.in.load}
  );
  assign rowOut.in.sop = 1'b0;
  Delay #(DATA_WIDTH, 1) colDelay (clk, rst_n, colIn.data, colOut.data);


  struct packed {
    logic [DATA_WIDTH-1:0] data;
    logic sop;
  } product, accDelayIn, accDelayOut, acc;

  multiplier #(DATA_WIDTH, DATA_WIDTH) multiplier (
    colIn.data, rowIn.in.data,
    product.data
  );
  assign product.sop = rowIn.in.sop;

  Delay #(DATA_WIDTH+1, LENGHT) accDelay (
    clk, rst_n,
    accDelayIn,
    accDelayOut
  );
  assign acc.data = accDelayOut.data + product.data;
  assign acc.sop = accDelayOut.sop;

  assign accDelayIn = rowIn.in.load? product : acc;

  logic resultSel;
  generate
    if(ACC_NUB > 2)begin
      Delay #(1, LENGHT*(ACC_NUB-2)) loadDelay (clk, rst_n, rowOut.in.load, resultSel);
    end else begin
      assign resultSel = rowOut.in.load;
    end
  endgenerate

  result_t resultReg;
  always_ff @(posedge clk or negedge rst_n) begin 
    if(!rst_n) begin
      resultReg <= '0;
    end else begin
      if(resultSel) begin
        resultReg.data <= acc.data;
        resultReg.sop <= acc.sop;
      end
      resultReg.eop <= rowIn.in.eop;
      resultReg.valid <= resultSel;
    end
  end

  assign rowOut.result.data = resultReg.valid? resultReg.data : rowIn.result.data;
  assign rowOut.result.eop = resultReg.eop;
  assign rowOut.result.sop = resultReg.valid? resultReg.sop : rowIn.result.sop;
  assign rowOut.result.valid = resultReg.valid | rowIn.result.valid;
endmodule

module sumDiffGen #(
  parameter LENGHT = 4, 
  parameter COL = 0
) (clk, rst_n, in, out);

  input logic clk, rst_n;
  input dctPort_t in;
  output in_t out;

  struct {in_t current, next;} outReg;
  always_ff @(posedge clk or negedge rst_n)
    outReg.current <= !rst_n ? '0 : outReg.next;
  assign out = outReg.current;

  logic [$clog2(LENGHT*COL)-1:0] cnt;
  always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n)
      cnt <= 0;
    else if(in.valid)
      cnt <= cnt + 1;
  end

  dctPort_t diffDelayIn, diffDelayOut; 
  Delay #($bits(dctPort_t), LENGHT/2) Dealy (
    clk, rst_n, diffDelayIn, diffDelayOut
  );
  logic sumDiffSel;
  logic [$bits(in.data)-1:0] sum, diff;
  always_comb begin
    diff = diffDelayOut.data - in.data;
    sum = diffDelayOut.data + in.data;
    sumDiffSel = cnt[$clog2(LENGHT)-1] & in.valid;
    diffDelayIn = in;
    diffDelayIn.valid = ~|cnt[$bits(cnt)-1:$clog2(LENGHT)] & in.valid;
    outReg.next = diffDelayOut;
    if(sumDiffSel) begin
      diffDelayIn.data = diff;
      outReg.next.data = sum;
    end
  end
endmodule

module coefficientMap #(
  parameter DATA_WIDTH = 8,
  parameter COL = 4
) (
  input logic clk,
  rom_if.tx a
);

  reg [DATA_WIDTH-1:0]  memoryArray[4];
  always_ff @(posedge clk)
    if(a.en)
      a.data <= memoryArray[a.addr];

  localparam real PI = 3.14159265358979323846;  // Define π manually
  function int getConst(int i);
    real cosine_val;
    real result;
    cosine_val = (i==0) ? $cos(4.0 * PI / 16.0) : $cos(i * PI / 16.0);
    result = cosine_val * (2.0**(DATA_WIDTH-1));
    return int'(result);
  endfunction

  always_comb begin
    if(COL == 0) begin
      memoryArray[0] = getConst(0);
      memoryArray[1] = getConst(1);
      memoryArray[2] = getConst(0);
      memoryArray[3] = getConst(3);
      memoryArray[4] = getConst(0);
      memoryArray[5] = getConst(4);
      memoryArray[6] = getConst(0);
      memoryArray[7] = getConst(6);
    end else if(COL == 1) begin
      memoryArray[0] = getConst(2);
      memoryArray[1] = getConst(3);
      memoryArray[2] = getConst(5);
      memoryArray[3] = -1 * getConst(6);
      memoryArray[4] = -1 * getConst(5);
      memoryArray[5] = -1 * getConst(1);
      memoryArray[6] = -1 * getConst(2);
      memoryArray[7] = -1 * getConst(4);
    end else if(COL == 2) begin
      memoryArray[0] = getConst(0);
      memoryArray[1] = getConst(4);
      memoryArray[2] = -1 * getConst(0);
      memoryArray[3] = -1 * getConst(1);
      memoryArray[4] = -1 * getConst(0);
      memoryArray[5] = getConst(6);
      memoryArray[6] = getConst(0);
      memoryArray[7] = getConst(3);
    end else begin
      memoryArray[0] = getConst(5);
      memoryArray[1] = getConst(6);
      memoryArray[2] = -1 * getConst(2);
      memoryArray[3] = -1 * getConst(4);
      memoryArray[4] = getConst(2);
      memoryArray[5] = getConst(3);
      memoryArray[6] = -1 * getConst(5);
      memoryArray[7] = -1 * getConst(1);
    end
  end
endmodule
