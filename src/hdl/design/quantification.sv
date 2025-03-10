`include "interface.sv"
module Quantizer #(
    parameter DATA_WIDTH = 10,
    parameter CHROMA = 1
) (
    ramWr_if.Rx in,
    output dctPort_t out
);
    logic signed [15 : 0] coefficientMap [64];

    wire signed [DATA_WIDTH-1 : 0] dataIn, dataOut;
    wire signed [DATA_WIDTH+16 : 0] product;
    assign dataIn = in.data;
    assign product = dataIn * coefficientMap[in.addr];
    assign dataOut = product >>> 16;
    assign out.data = in.en? dataOut : '0;
    assign out.valid = in.en;

    int n;
    initial begin
        for(n=0; n<64; n++)
            coefficientMap [n] = 2**16 / 99;

        if(CHROMA) begin
            coefficientMap [0] = 2**16 / 17;
            coefficientMap [1] = 2**16 / 18;
            coefficientMap [3] = 2**16 / 24;
            coefficientMap [4] = 2**16 / 47;
            coefficientMap [8] = 2**16 / 18;
            coefficientMap [9] = 2**16 / 21;
            coefficientMap [10] = 2**16 / 26;
            coefficientMap [11] = 2**16 / 66;
            coefficientMap [16] = 2**16 / 24;
            coefficientMap [17] = 2**16 / 26;
            coefficientMap [18] = 2**16 / 56;
            coefficientMap [24] = 2**16 / 47;
            coefficientMap [25] = 2**16 / 66;
        end else begin
            coefficientMap[0] = 2**16 / 16;
            coefficientMap[1] = 2**16 / 11;
            coefficientMap[2] = 2**16 / 10;
            coefficientMap[3] = 2**16 / 16;
            coefficientMap[4] = 2**16 / 24;
            coefficientMap[5] = 2**16 / 40;
            coefficientMap[6] = 2**16 / 51;
            coefficientMap[7] = 2**16 / 61;
            coefficientMap[8] = 2**16 / 12;
            coefficientMap[9] = 2**16 / 12;
            coefficientMap[10] = 2**16 / 14;
            coefficientMap[11] = 2**16 / 19;
            coefficientMap[12] = 2**16 / 26;
            coefficientMap[13] = 2**16 / 58;
            coefficientMap[14] = 2**16 / 60;
            coefficientMap[15] = 2**16 / 55;
            coefficientMap[16] = 2**16 / 14;
            coefficientMap[17] = 2**16 / 13;
            coefficientMap[18] = 2**16 / 16;
            coefficientMap[19] = 2**16 / 24;
            coefficientMap[20] = 2**16 / 40;
            coefficientMap[21] = 2**16 / 57;
            coefficientMap[22] = 2**16 / 69;
            coefficientMap[23] = 2**16 / 56;
            coefficientMap[24] = 2**16 / 14;
            coefficientMap[25] = 2**16 / 17;
            coefficientMap[26] = 2**16 / 22;
            coefficientMap[27] = 2**16 / 29;
            coefficientMap[28] = 2**16 / 51;
            coefficientMap[29] = 2**16 / 87;
            coefficientMap[30] = 2**16 / 80;
            coefficientMap[31] = 2**16 / 62;
            coefficientMap[32] = 2**16 / 18;
            coefficientMap[33] = 2**16 / 22;
            coefficientMap[34] = 2**16 / 37;
            coefficientMap[35] = 2**16 / 56;
            coefficientMap[36] = 2**16 / 68;
            coefficientMap[37] = 2**16 / 109;
            coefficientMap[38] = 2**16 / 103;
            coefficientMap[39] = 2**16 / 77;
            coefficientMap[40] = 2**16 / 24;
            coefficientMap[41] = 2**16 / 35;
            coefficientMap[42] = 2**16 / 55;
            coefficientMap[43] = 2**16 / 64;
            coefficientMap[44] = 2**16 / 81;
            coefficientMap[45] = 2**16 / 104;
            coefficientMap[46] = 2**16 / 113;
            coefficientMap[47] = 2**16 / 92;
            coefficientMap[48] = 2**16 / 49;
            coefficientMap[49] = 2**16 / 64;
            coefficientMap[50] = 2**16 / 78;
            coefficientMap[51] = 2**16 / 87;
            coefficientMap[52] = 2**16 / 103;
            coefficientMap[53] = 2**16 / 121;
            coefficientMap[54] = 2**16 / 120;
            coefficientMap[55] = 2**16 / 101;
            coefficientMap[56] = 2**16 / 72;
            coefficientMap[57] = 2**16 / 92;
            coefficientMap[58] = 2**16 / 95;
            coefficientMap[59] = 2**16 / 98;
            coefficientMap[60] = 2**16 / 112;
            coefficientMap[61] = 2**16 / 100;
            coefficientMap[62] = 2**16 / 103;
            coefficientMap[63] = 2**16 / 99;
        end
    end
endmodule
