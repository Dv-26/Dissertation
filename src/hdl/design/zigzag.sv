`include "interface.sv"
module Zigzag #(
    parameter DATA_WIDTH = 10
) (
    input wire rst_n,
    input dctPort_t in,
    ramWr_if.Tx out,
    output logic done
);

    logic [5:0] cnt64;
    always_ff @(posedge out.clk or negedge rst_n)begin
        if(!rst_n)
            cnt64 <= 0;
        else if(in.valid)
            cnt64 <= cnt64 + 1;
    end

    logic [2:0] scanX, scanY;
    logic scanValid, scanStart, scanDone;
    Scanner #(8, 8) scanner (out.clk, rst_n, scanStart, scanDone, scanX, scanY, scanValid);
    ramRd_if #(DATA_WIDTH, 64) ram8x8Rd (out.clk);
    ramWr_if #(DATA_WIDTH, 64) ram8x8Wr (out.clk);
    assign scanStart = cnt64 == 27;

    Ram #(DATA_WIDTH, 64) ram8x8 (ram8x8Wr, ram8x8Rd);

    assign ram8x8Wr.data = in.data;
    assign ram8x8Wr.addr = cnt64;
    assign ram8x8Wr.en = in.valid;
    assign out.data = ram8x8Rd.data;
    assign ram8x8Rd.addr = {scanY, scanX};
    assign ram8x8Rd.en = scanValid;
        
    Delay #(7, 1)delay1(
        out.clk, rst_n,
        {scanY, scanX, scanValid},
        {out.addr, out.en}
    );

    always_ff @(posedge out.clk or negedge rst_n) 
        if(!rst_n)
            done <= 1'b0;
        else 
            done <= scanDone;

endmodule

module Scanner #(
    parameter COL = 8,
    parameter ROW = 8
) (
    input logic clk,
    input logic rst_n,

    input logic start,
    output logic done,

    output logic [$clog2(COL)-1 : 0] x,
    output logic [$clog2(ROW)-1 : 0] y,
    output logic valid
);
    logic [$clog2(COL)-1 : 0] xCnt, xCnt_n;
    logic [$clog2(ROW)-1 : 0] yCnt, yCnt_n;

    logic zero, up, down, right, left;
    logic xEqCol, yEqRow, direction;
    always_ff @(posedge clk or negedge rst_n)begin
        if(!rst_n)begin
            xCnt <= 0;
            yCnt <= 0;
        end else begin
            xCnt <= xCnt_n;
            yCnt <= yCnt_n;
        end
    end
    assign xEqCol = xCnt == COL-1;
    assign yEqRow = yCnt == ROW-1;
    assign direction = xCnt[0] ^ yCnt[0];

    always_comb begin
        xCnt_n = xCnt;
        yCnt_n = yCnt;
        if (zero) begin
            xCnt_n = 0;
            yCnt_n = 0;
        end else begin
            case ({right, left})
                2'b01:
                    if(xCnt > 0)
                        xCnt_n = xCnt - 1;
                2'b10:
                    if(!xEqCol)
                        xCnt_n = xCnt + 1;
            endcase

            case ({down, up})
                2'b01:
                    if(yCnt > 0)
                        yCnt_n = yCnt - 1;
                2'b10:
                    if(!yEqRow)
                        yCnt_n = yCnt + 1;
            endcase
        end
    end

    typedef enum logic [1:0] {
        IDLE,
        SCAN,
        DONE
    } state_t;

    state_t state, state_n;

    always_ff @(posedge clk or negedge rst_n)
        if(!rst_n)
            state <= IDLE;
        else
            state <= state_n;

    always_comb begin
        state_n = state;
        {done, valid, zero, right, left, down, up} = '0;
        case (state)
            IDLE:begin 
                if(start)
                    state_n = SCAN;
            end
            SCAN:begin
                valid = 1;
                if(xEqCol && yEqRow)begin
                    zero = 1;
                    if(start) begin
                        done = 1;
                    end else begin
                        state_n = DONE;
                    end
                end else begin
                    if(!direction)begin
                        if(xEqCol) begin
                            down = 1;
                        end else if(yCnt == 0)begin
                            right = 1;
                        end else begin
                            up = 1;
                            right = 1;
                        end
                    end else begin
                        if(yEqRow) begin
                            right = 1;
                        end else if(xCnt == 0) begin
                            down = 1;
                        end else begin
                            down = 1;
                            left = 1;
                        end
                    end
                end
            end
            DONE:begin
                state_n = IDLE;
                done = 1;
            end
        endcase
    end

    assign x = xCnt;
    assign y = yCnt;
endmodule
