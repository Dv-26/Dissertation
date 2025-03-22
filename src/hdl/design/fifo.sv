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
    assign rd.empty = |ptr;
    always_ff @(posedge clk) begin
        for(int i=0; i<DEPTH; i++)
            if(!wr.full & wr.en)
                shiftReg[i] <= i == 0 ? wr.data : shiftReg[i-1];
    end
    always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n)
            ptr <= '0;
        else if(rst)
            ptr <= '0;
        else if(!wr.full & wr.en)
            ptr <= ptr + 1;
        else if(!rd.empty & rd.en)
            ptr <= ptr - 1;
    end
    assign rd.data = shiftReg[ptr];
endmodule