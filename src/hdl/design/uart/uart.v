`timescale 1ns / 1ps
module uart_top(
    input wire clk,
    input wire rst_n,
    input wire rx, 
    output wire tx 
);

    localparam INIT    = 2'd0;
    localparam SENDING = 2'd1;
    localparam LOOP    = 2'd2;

    reg [1:0] state = INIT;
    reg start_tx = 0;
    reg [7:0] tx_data;
    wire tx_busy;
    wire [7:0] rx_data;
    wire rx_done;

    reg [3:0] send_index = 0;
    reg [7:0] send_buf [12:0];

    reg [7:0] tx_buf;
    reg tx_req;

    initial begin
        send_buf[0]  = "h";
        send_buf[1]  = "e";
        send_buf[2]  = "l";
        send_buf[3]  = "l";
        send_buf[4]  = "o";
        send_buf[5]  = "f";
        send_buf[6]  = "p";
        send_buf[7]  = "g";
        send_buf[8]  = "a";
        send_buf[9]  = ".";
        send_buf[10] = "c";
        send_buf[11] = "o";
        send_buf[12] = "m";
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= INIT;
            send_index <= 0;
            start_tx <= 0;
            tx_req <= 0;
        end else begin
            case (state)
                INIT: begin
                    state <= SENDING;
                    send_index <= 0;
                end

                SENDING: begin
                    if (!tx_busy && !start_tx && send_index < 13) begin
                        tx_data <= send_buf[send_index];
                        start_tx <= 1;
                        send_index <= send_index + 1;
                    end else if (start_tx && tx_busy) begin
                        start_tx <= 0;
                    end else if (send_index >= 13 && !tx_busy) begin
                        state <= LOOP;
                    end
                end

                LOOP: begin
                    if (rx_done && !tx_req) begin
                        tx_buf <= rx_data;
                        tx_req <= 1;
                    end

                    if (tx_req && !tx_busy && !start_tx) begin
                        tx_data <= tx_buf;
                        start_tx <= 1;
                        tx_req <= 0;
                    end else if (start_tx && tx_busy) begin
                        start_tx <= 0;
                    end
                end
            endcase
        end
    end

    uart_tx #(
        .CLK_FREQ(50000000),
        .BAUD_RATE(115200)
    ) u_tx (
        .clk(clk),
        .rst_n(rst_n),
        .tx_data(tx_data),
        .tx_start(start_tx),
        .tx(tx),
        .tx_busy(tx_busy)
    );

    uart_rx #(
        .CLK_FREQ(50000000),
        .BAUD_RATE(115200)
    ) u_rx (
        .clk(clk),
        .rst_n(rst_n),
        .rx(rx),
        .rx_data(rx_data),
        .rx_done(rx_done)
    );

endmodule
