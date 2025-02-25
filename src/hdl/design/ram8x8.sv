module ram #(
    parameter  WIDTH = 8,
    parameter  DEPTH = 64
) (
    clk,
    din, wr_addr, wr_en,
    dout, rd_addr, rd_en
);

localparam ADDR_W = $clog2(DEPTH);
input logic clk;

input logic [WIDTH-1:0] din;
input logic [ADDR_W-1:0]    wr_addr;
input logic wr_en;

output logic [WIDTH-1:0] dout;
input logic [ADDR_W-1:0]    rd_addr;
input logic rd_en;

reg [WIDTH-1:0] memoryArray[DEPTH];

always @(posedge clk)begin
    if(rd_en)
        dout <= memoryArray[rd_addr];
    
    if(wr_en)
        memoryArray[wr_addr] <= din;
end

endmodule
