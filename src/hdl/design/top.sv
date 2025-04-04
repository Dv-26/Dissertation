`include "interface.sv"
`include "entropyCoder.svh"

module top #(
    parameter WIDTH = 1280,
    parameter HEIGHT = 720
) (
    // `ifndef __SIM__
    //     inout sda, scl, pwdn, rst,
    //     (* MARK_DEBUG="true" *)input logic pclk, vsync, href,
    //     (* MARK_DEBUG="true" *)input logic [7:0] data
    // `else
        input logic clk, rst_n,
        input logic pclk, vsync, href,
        input logic [7:0] data,
        output [$bits(tempCode_t)-1:0] out[3]
    // `endif
);

    (* MARK_DEBUG="true" *)dctPort_t pingpong2Code[3]; 

    // `ifndef __SIM__
    // wire clk, rst_n;
    //     ps_wrapper ps (
    //         .FCLK_CLK0_0 (clk),
    //         .FCLK_RESET0_N_0 (rst_n),
    //         .IIC_0_0_scl_io (scl),
    //         .IIC_0_0_sda_io (sda),
    //         .GPIO_0_0_tri_io ({rst, pwdn})
    //     );
    // `else
        JpegCode #(10, 3) coder (clk, rst_n, pingpong2Code, out);
    // `endif

    PingpongBuf #(WIDTH, HEIGHT, "RGB565") pingpongBuf (
        clk, rst_n,
        pclk, vsync, href, data,
        pingpong2Code
    );

endmodule
