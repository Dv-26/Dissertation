`timescale 1ns / 1ps
module uart_tx #(
    parameter CLK_FREQ = 50000000,
    parameter BAUD_RATE = 115200
)(
    input wire clk,
    input wire rst_n,
    input wire [7:0] tx_data,
    input wire tx_start,
    output reg tx,
    output reg tx_busy
);

    localparam BAUD_TICK = CLK_FREQ / BAUD_RATE;

    reg [15:0] baud_cnt = 0;
    reg [3:0] bit_idx = 0;
    reg [9:0] tx_shift = 10'b1111111111;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx <= 1;
            tx_busy <= 0;
            baud_cnt <= 0;
            bit_idx <= 0;
            tx_shift <= 10'b1111111111;
        end 
        else begin
            if (tx_start && !tx_busy) begin
                tx_shift <= {1'b1, tx_data, 1'b0};
                tx_busy <= 1;
                baud_cnt <= 0;
                bit_idx <= 0;
            end 
            else if (tx_busy) begin
                if (baud_cnt == BAUD_TICK - 1) begin
                    baud_cnt <= 0;
                    tx <= tx_shift[bit_idx];
                    bit_idx <= bit_idx + 1;

                    if (bit_idx == 9) begin
                        tx_busy <= 0;
                        tx <= 1;
                    end
                end 
                else begin
                    baud_cnt <= baud_cnt + 1;
                end
            end
        end
    end
endmodule