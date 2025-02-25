`include "interface.sv"

module dct #(
  parameter DATA_WIDTH = 8
) (
  input logic clk,
  input logic rst_n,

  input dctPort_t x,
  output dctPort_t y
);

  logic [DATA_WIDTH-1:0] coefficient[4];

  x2zX_t xIn;
  dctPort_t z;
  assign coefficient[0] = 1;
  assign coefficient[1] = 1;
  assign coefficient[2] = 1;
  assign coefficient[3] = 1;
 // logic [DATA_WIDTH-1:0] z;
  logic [2:0] cnt8;
  always_ff @(posedge clk or negedge rst_n)begin
    if(!rst_n) begin
      cnt8 <= 0;
    end else begin 
      if(x.valid)
        cnt8 <= cnt8 + 1;
    end
  end
  assign xIn.data = x.data;
  assign xIn.sumDiffSel = cnt8[0];
  assign xIn.load = ~|cnt8[2:1] & x.valid;
  x2zArray #(DATA_WIDTH, 4) x2z (clk, rst_n, coefficient, xIn, z);

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
  logic [DATA_WIDTH-1:0] delay8In, delay8Out;
  Delay #(DATA_WIDTH+1, 8)delay8(clk, rst_n, delay8In, delay8Out);
  assign delay8In = sel? z.data-delay8Out : z.data;
  assign sumDiff.data = sel? delay8Out+z.data : delay8Out;
  assign sel = cnt16[3] & z.valid;

  logic sumDiffValid;
  Delay #(1, 8)validDelay(clk, rst_n, z.valid, sumDiffValid);

  logic [5:0] cnt64;
  always_ff @(posedge clk or negedge rst_n)begin
    if(!rst_n) begin
      cnt64 <= 0;
    end else begin
      if(sumDiffValid)
        cnt64 <= cnt64 + 1;
    end
  end

  assign sumDiff.load = ~|cnt64[5:4] & sumDiffValid;
  z2yArray #(DATA_WIDTH, 4) z2y (clk, rst_n, coefficient, sumDiff, y);
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
      assign sum = rowPort[i].x.data + xDelay2[0].data;
      assign diff = xDelay2[0].data - xDelay2[1].data;
       
      logic [DATA_WIDTH-1:0] product;
      assign product = coefficient[i] * (xDelay2[0].sumDiffSel? diff : sum);

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
      assign product = coefficient[i] * rowPort[i].z.data;
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
