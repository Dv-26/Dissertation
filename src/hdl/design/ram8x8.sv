`include "interface.sv"

module Ram #(
  parameter WIDTH = 10,
  parameter DEPTH = 64,
) (
  ram_if.WrRx wr,
  ram_if.RdTx rd
);

reg [WIDTH-1:0] memoryArray[DEPTH];

always_ff @(posedge rd.clk)begin
    if(rd.en)
        rd.data <= memoryArray[rd.addr];
end

always_ff @(posedge wr.clk)begin
  if(wr.en)
    memoryArray[wr.addr] <= wr.data;
end

endmodule
