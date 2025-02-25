`include "interface.sv"
module jpegCode #(
    parameter DATA_WIDTH = 8
) (
    input logic clk,
    input logic rst_n,
    input dctPort_t x,
    output dctPort_t y
);

dctPort_t dctOut;
dct #(DATA_WIDTH) dct (clk, rst_n, x, dctOut);

logic [5:0] cnt64;
always_ff @(posedge clk or negedge rst_n)begin
    if(!rst_n)
        cnt64 <= 0;
    else if(dctOut.valid)
        cnt64 <= cnt64 + 1;
end

logic [2:0] scanX, scanY;
logic scanValid, scanStart, scanDone;
zigzag #(8, 8) scanner (clk, rst_n, scanStart, scanDone, scanX, scanY, scanValid);
assign scanStart = cnt64 == 27;

ram #(DATA_WIDTH, 64) ram8x8 (
    .clk(clk),
    .din(dctOut.data),
    .wr_addr(cnt64),
    .wr_en(dctOut.valid),
    .dout(y.data),
    .rd_addr({scanY, scanX}),
    .rd_en(scanValid)
);

Delay #(1, 1)delay1(clk, rst_n, scanValid, y.valid);
endmodule