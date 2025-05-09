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

