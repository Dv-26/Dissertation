`include "interface.sv"
moudle PingpongBuf #(
  parameter WIDTH = 1280,
  parameter HEIGHT = 720,
  parameter DATA_FORMAT = "RGB888"
) (
  input logic clk, rst_n,

  input logic pclk, vsync, href,
  input logic [7:0] data,
);

  dctPort_t dvpOut; 
  logic [$clog2(WIDTH)-1:0] hCnt;
  logic [$clog2(HEIGHT)-1:0] vCnt;

  Dvp #(WIDTH, HEIGHT, DATA_FORMAT) dvp (
    rst_n,
    pclk, vsync, href, data,
    dvpOut, hCnt, VCnt
  );

  logic switch;
  assign switch = hCnt == WIDTH && (~|Vcnt[2:0]);

  ramRd_if #(24, WIDTH) buf0Out (clk);
  ramWr_if #(24, WIDTH) buf0In (pclk);
  Ram #(24, WIDTH*8) buf0 (buf0In, buf0Out);

  ramRd_if #(24, WIDTH) buf1Out (clk);
  ramWr_if #(24, WIDTH) buf1In (pclk);
  Ram #(24, WIDTH*8) buf1 (buf1In, buf1Out);

  logic wrBufSel, rdBufSel;
  assign buf1In.data = dvpOut.data;
  assign buf1In.addr = {vCnt[2:0], hCnt};
  assign buf0In.data = dvpOut.data;
  assign buf0In.addr = {vCnt[2:0], hCnt};
  assign {buf0In.en, buf1In.en} = wrBufSel ?
    {dvpOut.en, 1'b0} :
    {1'b0, dvpOut.en};

  logic cdcValidEx, cdcReadyEx;
  logic cdcValidIn, cdcReadyIn;
  logic [1:0] cdcValidEx2In, cdcReadyIn2Ex;



  always_ff @(posedge pclk or negedge rst_n) begin
    if(!rst_n) begin
      wrBufSel <= 0;
    end else begin
      if (switch & ready)
        wrBufSel <= !wrBufSel;
    end
  end
endmodule
