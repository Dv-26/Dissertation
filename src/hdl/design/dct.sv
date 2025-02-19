typedef struct {
  logic [DATA_WIDTH-1:0] x;
  logic [DATA_WIDTH-1:0] coefficient;
  logic [DATA_WIDTH-1:0] z;
  logic sumDiffSel;
  logic load;
} peBus_t #(parameter DATA_WIDTH = 8);


module Pe #(
  parameter DATA_WIDTH = 8
)(
  input   logic                   clk,
  input   logic                   rst_n,

  input   peBus_t #(DATA_WIDTH)   in,
  output  peBus_t #(DATA_WIDTH)   out
);

struct peBus_t #(DATA_WIDTH)  inDealy[2];
always_ff @(posedge clk)begin
  inDealy[0] <= in;
  inDealy[1] <= inDealy[0]
end

assign out.x = inDealy[1].x;
assign out.sumDiffSel = inDealy[1].sumDiffSel;
assign out.load = inDealy[1].load;

logic [DATA_WIDTH-1:0]  sum,diff;
assign sum = in.x + inDealy[0].x;
assign diff = inDealy[0].x - inDealy[1].x

logic [DATA_WIDTH-1:0]  product;
assign product = in.coefficient * (inDealy[0].sumDiffSel? sum : diff);

logic [DATA_WIDTH-1:0]  delay2In,delay2Out;
Delay #(DATA_WIDTH, 2)delay2(clk, delay2In, delay2Out);

logic [DATA_WIDTH-1:0] acc;
assign acc = product + delay2Out;
assing delay2In = inDealy[0].load? product : acc;

logic outSel; 
Delay #(1, 6)delay6(clk, inDealy.load[0], outSel); 
assign out.z = outSel? acc : in.z;
endmodule


