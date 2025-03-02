`include "interface.sv"
module JpegCode #(
    parameter DATA_WIDTH = 10,
    parameter ROW = 3
) (
    input logic clk,
    input logic rst_n,
    input dctPort_t in[ROW],
    output dctPort_t out[ROW]
);

dctPort_t y[ROW];
Dct #(DATA_WIDTH, ROW) dct (clk, rst_n, in, y);

generate
  genvar i;
  for(i=0; i<ROW; i++) begin
    logic [5:0] cnt64;
    always_ff @(posedge clk or negedge rst_n)begin
        if(!rst_n)
            cnt64 <= 0;
        else if(y[i].valid)
            cnt64 <= cnt64 + 1;
    end

    logic [2:0] scanX, scanY;
    logic scanValid, scanStart, scanDone;
    zigzag #(8, 8) scanner (clk, rst_n, scanStart, scanDone, scanX, scanY, scanValid);
    assign scanStart = cnt64 == 27;

    ram #(DATA_WIDTH, 64) ram8x8 (
        .clk(clk),
        .din(y[i].data),
        .wr_addr(cnt64),
        .wr_en(y[i].valid),
        .dout(out[i].data),
        .rd_addr({scanY, scanX}),
        .rd_en(scanValid)
    );

    Delay #(1, 1)delay1(clk, rst_n, scanValid, out[i].valid);
  end
endgenerate

endmodule
