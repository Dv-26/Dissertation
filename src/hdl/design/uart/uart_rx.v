module uart_rx #(
    parameter CLK_FREQ   = 50000000,
    parameter BAUD_RATE  = 115200
)(
    input wire clk,
    input wire rst_n,
    input wire rx,
    output reg [7:0] rx_data,
    output reg rx_done
);

    localparam BAUD_TICK = CLK_FREQ / BAUD_RATE;
    localparam HALF_BAUD = BAUD_TICK / 2;

    reg [15:0] baud_cnt = 0;
    reg [3:0]  bit_cnt = 0;
    reg [7:0]  rx_shift = 0;
    reg [1:0]  rx_sync = 2'b11;
    reg        rx_busy = 0;
    reg        start_edge = 0;

    always @(posedge clk) begin
        rx_sync <= {rx_sync[0], rx};
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            start_edge <= 0;
        else
            start_edge <= (!rx_busy && rx_sync == 2'b10);
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_busy   <= 0;
            rx_done   <= 0;
            baud_cnt  <= 0;
            bit_cnt   <= 0;
            rx_shift  <= 0;
            rx_data   <= 0;
        end 
        else begin
            rx_done <= 0;

            if (start_edge) begin
                rx_busy   <= 1;
                baud_cnt  <= 0;
                bit_cnt   <= 0;
            end

            if (rx_busy) begin
                baud_cnt <= baud_cnt + 1;

                if ((bit_cnt == 0 && baud_cnt == HALF_BAUD) || (bit_cnt > 0 && baud_cnt == BAUD_TICK)) begin
                    baud_cnt <= 0;
                    bit_cnt <= bit_cnt + 1;

                    if (bit_cnt >= 1 && bit_cnt <= 8) begin
                        rx_shift[bit_cnt - 1] <= rx_sync[1];
                    end

                    if (bit_cnt == 9) begin
                        rx_data <= rx_shift;
                        rx_done <= 1;
                        rx_busy <= 0;
                    end
                end
            end
        end
    end

endmodule