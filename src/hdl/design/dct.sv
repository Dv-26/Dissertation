`include "interface.sv"

module dct #(
  parameter DATA_WIDTH = 8
) (
  input logic clk,
  input logic rst_n,

  input dctPort_t x,
  output dctPort_t y
);

  logic [DATA_WIDTH-1:0] x2zCoefficient[4];

  x2zX_t xIn;
  dctPort_t z;
 
  logic cnt8Add;
  logic [2:0] cnt8;
  always_ff @(posedge clk or negedge rst_n)begin
    if(!rst_n) begin
      cnt8 <= 0;
    end else begin 
      if(cnt8Add)
        cnt8 <= cnt8 + 1;
    end
  end
  assign cnt8Add = x.valid | z.valid;
  assign xIn.data = x.data;
  assign xIn.sumDiffSel = cnt8[0];
  assign xIn.load = ~|cnt8[2:1] & x.valid;
  x2zArray #(DATA_WIDTH, 4) x2z (clk, rst_n, x2zCoefficient, xIn, z);

  logic [3:0] cnt16;
  always_ff @(posedge clk or negedge rst_n)begin
    if(!rst_n) begin
      cnt16 <= 0;
    end else begin
      if(z.valid)
        cnt16 <= cnt16 + 1;
    end
  end

  logic sel;
  z2yZ_t sumDiff;
  logic [DATA_WIDTH-1:0] z2yCoefficient[4];
  logic [DATA_WIDTH-1:0] delay8In, delay8Out;
  Delay #(DATA_WIDTH+1, 8)delay8(clk, rst_n, delay8In, delay8Out);
  assign delay8In = sel? delay8Out-z.data : z.data;
  assign sumDiff.data = sel? delay8Out+z.data : delay8Out;
  assign sel = cnt16[3] & z.valid;

  logic sumDiffValidAhead, sumDiffValid;
  Delay #(1, 7)validDelay7(clk, rst_n, z.valid, sumDiffValidAhead);
  Delay #(1, 1)validDelay8(clk, rst_n, sumDiffValidAhead, sumDiffValid);

  logic cnt64Add;
  logic [5:0] cnt64Ahead,cnt64;
  always_ff @(posedge clk or negedge rst_n)begin
    if(!rst_n) begin
      cnt64Ahead <= 0;
    end else begin
      if(cnt64Add)
        cnt64Ahead <= cnt64Ahead + 1;
    end
  end
  assign cnt64Add = sumDiffValidAhead | sumDiffValid | y.valid;
  Delay #(6, 1)cnt64Delay(clk, rst_n, cnt64Ahead, cnt64);

  assign sumDiff.load = ~|cnt64[5:4] & sumDiffValid;
  z2yArray #(DATA_WIDTH, 4) z2y (clk, rst_n, z2yCoefficient, sumDiff, y);

  coefficientMap #(DATA_WIDTH, 8) coefficientMap (
    clk,
    cnt8, cnt8Add, x2zCoefficient,
    cnt64Ahead[5:3], cnt64Add, z2yCoefficient
  );
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
module x2zArray #(
  parameter DATA_WIDTH = 8,
  parameter COL = 4
) (
  input logic clk,
  input logic rst_n,

  input logic [DATA_WIDTH-1:0]  coefficient[COL],
  input x2zX_t x,
  output dctPort_t z
);

// verilator lint_off UNOPTFLAT
  x2zPort_t rowPort[COL+1]; 
// verilator lint_on UNOPTFLAT
  assign rowPort[0].x = x;
  assign {rowPort[0].z.data, rowPort[0].z.valid} = '0;

  generate
    genvar i;
    for(i=0; i<COL; i++)begin: pe

      x2zX_t xDelay2[2];
      always_ff @(posedge clk or negedge rst_n)begin
        if(!rst_n) begin
          {xDelay2[0].data, xDelay2[0].sumDiffSel, xDelay2[0].load} <= '0; 
          {xDelay2[1].data, xDelay2[1].sumDiffSel, xDelay2[1].load} <= '0; 
        end else begin
          xDelay2[0] <= rowPort[i].x; 
          xDelay2[1] <= xDelay2[0];
        end
      end
      assign rowPort[i+1].x = xDelay2[1];

      logic [DATA_WIDTH-1:0] sum,diff;
      assign sum = xDelay2[0].data + rowPort[i].x.data;
      assign diff = xDelay2[1].data - xDelay2[0].data;
       
      logic [DATA_WIDTH-1:0] product;
      multiplier#(DATA_WIDTH, DATA_WIDTH) multiplier (
        coefficient[i],
        xDelay2[0].sumDiffSel? diff : sum,
        product
      );
      logic [DATA_WIDTH-1 : 0] delay2In, delay2Out, acc;
      assign delay2In = xDelay2[0].load? product : acc;
      assign acc = product + delay2Out;
      Delay #(DATA_WIDTH, 2)delay2(clk, rst_n, delay2In, delay2Out);

      logic outSel;
      Delay #(1, 6)delay6(clk, rst_n, xDelay2[0].load, outSel);
      assign rowPort[i+1].z.data = outSel?  acc : rowPort[i].z.data;
      assign rowPort[i+1].z.valid = rowPort[i].z.valid | outSel;
    end
  endgenerate

  assign z = rowPort[COL].z;
endmodule

module z2yArray #(
  parameter DATA_WIDTH = 8,
  parameter COL = 4
) (
  input   wire  clk,
  input   wire  rst_n,

  input   logic [DATA_WIDTH-1:0]  coefficient[COL],
  input   z2yZ_t z,
  output  dctPort_t y
);
// verilator lint_off UNOPTFLAT
  z2yPort_t rowPort[COL+1];
// verilator lint_on UNOPTFLAT
  assign rowPort[0].z = z;
  assign {rowPort[0].y.data, rowPort[0].y.valid} = '0;
  generate 
    genvar i;
    for (i=0; i<COL; i++) begin: pe
      Delay #(DATA_WIDTH+1, 16) rowDelay16 (
        clk, rst_n,
        {rowPort[i].z.data, rowPort[i].z.load},
        {rowPort[i+1].z.data, rowPort[i+1].z.load}
      );

      logic [DATA_WIDTH-1 : 0] product, acc, delay16In, delay16Out;
      multiplier#(DATA_WIDTH, DATA_WIDTH) multiplier (
        coefficient[i],
        rowPort[i].z.data,
        product
      );
      assign acc = product + delay16Out;
      Delay #(DATA_WIDTH, 16) delay16 (clk, rst_n, delay16In, delay16Out);
      assign delay16In = rowPort[i].z.load? product : acc;

      logic outSel;
      Delay #(1, 48) delay48 (clk, rst_n, rowPort[i+1].z.load, outSel);
      assign rowPort[i+1].y.data = outSel? acc : rowPort[i].y.data;
      assign rowPort[i+1].y.valid = rowPort[i].y.valid | outSel;
    end
  endgenerate

  assign y = rowPort[COL].y;

endmodule

module coefficientMap #(
  parameter DATA_WIDTH = 8,
  parameter DEPTH = 8
) (
  input logic clk,

  input logic [$clog2(DEPTH)-1:0] addra,
  input logic ena,
  output logic [DATA_WIDTH-1:0] douta[4],

  input logic [$clog2(DEPTH)-1:0] addrb,
  input logic enb,
  output logic [DATA_WIDTH-1:0] doutb[4]
);

  reg [DATA_WIDTH-1:0]  memoryArray[DEPTH][4];
  always @(posedge clk)begin
    if(ena)
      douta <= memoryArray[addra];
    if(enb)
      doutb <= memoryArray[addrb];
  end

  localparam real PI = 3.14159265358979323846;  // Define π manually
  logic signed [DATA_WIDTH-1:0] cos[7];
  int i;
  initial begin
    for(i=0; i<7; i++)begin
      if(i == 0)
        cos[i] = $cos(4*PI / 16) * 2**(DATA_WIDTH-1);
      else
        cos[i] = $cos(i*PI / 16) * 2**(DATA_WIDTH-1);
    end
    memoryArray[0] = {cos[0], -1*cos[2], -1*cos[0], -1*cos[2]};
    memoryArray[1] = {cos[1], -1*cos[4], cos[6], -1*cos[4]};
    memoryArray[2] = {cos[0], cos[2], cos[0], cos[2]};
    memoryArray[3] = {cos[3], cos[3], cos[3], cos[3]};
    memoryArray[4] = {cos[0], cos[5], cos[0], -1*cos[5]};
    memoryArray[5] = {cos[4], -1*cos[6], cos[4], -1*cos[1]};
    memoryArray[6] = {cos[0], -1*cos[5], -1*cos[0], cos[5]};
    memoryArray[7] = {cos[6], -1*cos[1], -1*cos[1], cos[6]};
  end
endmodule