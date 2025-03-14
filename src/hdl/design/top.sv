`include "interface.sv"
module top #(
    parameter WIDTH = 1280,
    parameter HEIGHT = 720
) (
    input logic clk, rst_n,
    input logic pclk, vsync, href,
    input logic [7:0] data,
    output dctPort_t out[3]
);

    dctPort_t pingpong2Code[3]; 

    PingpongBuf #(WIDTH, HEIGHT, "RGB888") pingpongBuf (
        clk, rst_n,
        pclk, vsync, href, data,
        pingpong2Code
    );

    JpegCode #(10, 3) coder (clk, rst_n, pingpong2Code, out);
endmodule
