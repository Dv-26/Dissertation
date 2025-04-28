`timescale 1ns/1ns
// `include "interface.sv"

module dct_tb ();

    localparam DATA_WIDTH = 10;
    localparam ROW = 1;

    logic clk, rst_n;
    
    always #1 clk = ~clk;
    initial begin
        rst_n = 0;
        clk = 1;
    end

    dctPort_t stimulate, in[ROW], out[ROW];

    generate
        genvar n;
        for(n=0; n<ROW; n++)begin
            assign in[n] = stimulate; 
        end
    endgenerate

    Dct #( DATA_WIDTH, ROW) dct_tb (clk, rst_n, in, out);
    int i, j;
    initial begin
        stimulate.data = 0;
        stimulate.valid = 0;
        #10
        rst_n = 1;
        for(i=0; i<8; i++) begin
            for(j=0; j<8; j++) begin
                @(posedge clk);
                stimulate.valid <= 1;
                stimulate.data <= (j%2)?  70-(j/2)*10 : j/2*10;
            end
        end
        @(posedge clk);
        stimulate.data = 0;
        stimulate.valid = 0;
        #100
        $stop();
    end

endmodule
