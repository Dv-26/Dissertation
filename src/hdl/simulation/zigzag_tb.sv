// `include "../design/interface.sv"
module zigzag_tb;
  
  parameter DATA_WIDTH = 8;

  logic                   clk;
  logic                   rst_n;

  always #5 clk = ~clk;

logic start;
logic done;
// logic [2:0] x;
// logic [2:0] y;
logic valid;

// zigzag #(
//   .COL 	(8  ),
//   .ROW 	(8  ))
// u_zigzag(
//   .clk   	(clk    ),
//   .rst_n 	(rst_n  ),
//   .start 	(start  ),
//   .done  	(done   ),
//   .x     	(x      ),
//   .y     	(y      ),
//   .valid 	(valid  )
// );

wire [$clog2(8) + 3-1:0] addr;

RdAddrGen #(
  .WIDTH 	(16))
u_RdAddrGen(
  .clk   	(clk    ),
  .rst_n 	(rst_n  ),
  .start 	(start  ),
  .done  	(done   ),
  .valid 	(valid  ),
  .addr  	(addr   )
);

  int i,j;
  initial begin
    clk = 1;
    rst_n = 0;
    start = 0;
    #5
    rst_n = 1;
    #5;
    @(posedge clk)
      start <= 1;
    @(posedge clk)
      start <= 0;
    #1000;
    $stop();
  end
endmodule
