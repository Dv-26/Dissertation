module ShiftFIFO #(
  parameter WIDTH = 10,
  parameter DEPTH = 3
) (
    input logic clk, rst_n, rst, 
    fifoWr_if.syncRx wr,
    fifoRd_if.syncTx rd
);
  logic [$clog2(DEPTH)-1:0] ptr;
  logic [WIDTH-1:0] shiftReg [DEPTH];
  assign wr.full = ptr == DEPTH-1;
  assign rd.empty = ~|ptr;
  always_ff @(posedge clk) begin
    for(int i=0; i<DEPTH; i++)
      if(!wr.full & wr.en)
        shiftReg[i] <= i == 0 ? wr.data : shiftReg[i-1];
  end
  always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      ptr <= '0;
    end else if(rst) begin
      ptr <= '0;
    end else begin 
      case ({wr.en, rd.en})
        2'b01: begin
          if(!rd.empty)
            ptr <= ptr - 1;
        end
        2'b10: begin
          if(!wr.full)
            ptr <= ptr + 1;
        end
      endcase
    end
  end
  assign rd.data = shiftReg[ptr-1];
endmodule
