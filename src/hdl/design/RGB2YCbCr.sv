`include "interface.sv"

module RGB2YCbCr #(
  parameter DATA_WIDTH = 10
) (
  input clk, rst_n,
  input dctPort_t in[3],
  output dctPort_t out[3]
);
  logic signed [DATA_WIDTH-1:0] ConstAaary[3][3];
  generate
    genvar i;
    for(i=0; i<3; i++) begin
      ProductsSumTree #(DATA_WIDTH, 3) colorTranform (
        clk, 
        {in[2].data, in[1].data, in[0].data},
        ConstAaary[i], out[i].data
      );  
    end

    localparam Delay = $clog2(3)+1;
    logic valid[Delay];
    for(i=0; i<Delay; i++) begin
        always_ff @(posedge clk or negedge rst_n)
          if(!rst_n)
            valid[i] <= 1'b0;
          else
            valid[i] <= i == 0 ?
              &{in[2].valid, in[1].valid, in[0].valid} :
              valid[i-1];
    end
    assign {out[2].valid, out[1].valid, out[0].valid} = {3{valid[Delay-1]}};
  endgenerate

  initial begin
    ConstAaary[0][0] = 1;
    ConstAaary[0][1] = 1;
    ConstAaary[0][2] = 1;

    ConstAaary[1][0] = 1;
    ConstAaary[1][1] = 1;
    ConstAaary[1][2] = 1;

    ConstAaary[2][0] = 1;
    ConstAaary[2][1] = 1;
    ConstAaary[2][2] = 1;
  end
endmodule

module ProductsSumTree #(
  parameter DATA_WIDTH = 10,
  parameter NUB = 3
) (
  input logic clk,
  input logic signed [DATA_WIDTH-1:0] in[NUB], constIn[NUB],
  output logic [DATA_WIDTH-1:0] out
);
  
  logic [DATA_WIDTH-1:0] product[2][NUB];
  generate
    genvar i, j;
    for(i=0; i<NUB; i++) begin: mul
      multiplier #(DATA_WIDTH, DATA_WIDTH) multiplier (
        constIn[i], in[i], product[0][i]
      );
      always_ff @(posedge clk)
        product[1][i] <= product[0][i];
    end
  endgenerate
  AddTree #(DATA_WIDTH, NUB) sumTree (clk, product[1], out);
endmodule

module AddTree #(
  parameter DATA_WIDTH = 10,
  parameter NUB = 7
) (
  input logic clk,
  input logic [DATA_WIDTH-1:0] in[NUB],
  output logic [DATA_WIDTH-1:0] out
);
  
  generate
    if(NUB == 2) begin
      always_ff @(posedge clk)
        out <= in[0] + in[1];
    end else begin 
      logic [DATA_WIDTH-1:0] subSum[2];
      genvar i,j;

      if(NUB%2 != 0) begin
        localparam DELAY = $clog2(NUB-1);
        logic [DATA_WIDTH-1:0] InDelay[DELAY];
        for(i=0; i<DELAY; i++)
          always_ff @(posedge clk)
            InDelay[i] <= i == 0 ? in[NUB-1] : InDelay[i-1];
        assign subSum[1] = InDelay[DELAY-1];

        logic [DATA_WIDTH-1:0] subIn[NUB-1];
        for(i=0; i<NUB-1; i++)
          assign subIn[i] = in[i];
        AddTree #(DATA_WIDTH, NUB-1) subTree (clk, subIn, subSum[0]);
      end else begin
        logic [DATA_WIDTH-1:0] subIn[2][NUB/2];
        for(i=0; i<2; i++)
          for(j=0; j<NUB/2; j++)
            assign subIn[i][j] = in[NUB/2*i + j];
        AddTree #(DATA_WIDTH, NUB/2) subTree0 (clk, subIn[0], subSum[0]);
        AddTree #(DATA_WIDTH, NUB/2) subTree1 (clk, subIn[1], subSum[1]);
      end

      AddTree #(DATA_WIDTH, 2) sub (clk, subSum, out);
    end
  endgenerate
endmodule
