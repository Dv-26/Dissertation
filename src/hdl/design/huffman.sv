
module HuffmanCoder #(

) (
  input logic clk, rst_n,
  input logic size
);

endmodule

module DcHuffmanMap #(
  parameter CHROMA = 1
) (
  input tempCodeData_t in,
  output dcHuffman_t out
);

  dcHuffman_t memoryArray [12];
  initial begin
    if(CHROMA == 0) begin
      memoryArray[0].code = 11'b00000000000;
      memoryArray[0].size = 2;

      memoryArray[1].code = 11'b00000000010;
      memoryArray[1].size = 3;

      memoryArray[2].code = 11'b00000000011;
      memoryArray[2].size = 3;

      memoryArray[3].code = 11'b00000000100;
      memoryArray[3].size = 3;

      memoryArray[4].code = 11'b00000000101;
      memoryArray[4].size = 3;

      memoryArray[5].code = 11'b00000000110;
      memoryArray[5].size = 3;

      memoryArray[6].code = 11'b00000001110;
      memoryArray[6].size = 4;

      memoryArray[7].code = 11'b00000011110;
      memoryArray[7].size = 5;

      memoryArray[8].code = 11'b00000111110;
      memoryArray[8].size = 6;

      memoryArray[9].code = 11'b00001111110;
      memoryArray[9].size = 7;

      memoryArray[10].code = 11'b00111111110;
      memoryArray[10].size = 8;

      memoryArray[11].code = 11'b01111111110;
      memoryArray[11].size = 9;
    end else begin
      memoryArray[0].code = 11'b00000000000;
      memoryArray[0].size = 2;

      memoryArray[1].code = 11'b00000000001;
      memoryArray[1].size = 2;

      memoryArray[2].code = 11'b00000000010;
      memoryArray[2].size = 2;

      memoryArray[3].code = 11'b00000000110;
      memoryArray[3].size = 3;

      memoryArray[4].code = 11'b00000001110;
      memoryArray[4].size = 4;

      memoryArray[5].code = 11'b00000011110;
      memoryArray[5].size = 5;

      memoryArray[6].code = 11'b00000111110;
      memoryArray[6].size = 6;

      memoryArray[7].code = 11'b00001111110;
      memoryArray[7].size = 7;

      memoryArray[8].code = 11'b00011111110;
      memoryArray[8].size = 8;

      memoryArray[9].code = 11'b00111111110;
      memoryArray[9].size = 9;

      memoryArray[10].code = 11'b01111111110;
      memoryArray[10].size = 10;

      memoryArray[11].code = 11'b11111111110;
      memoryArray[11].size = 11;
    end
  end

endmodule
