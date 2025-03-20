`include "interface.sv"

module EntropyCoder #(
    parameter DATA_WIDTH = 10
) (
    input clk, rst_n,
    input codePort_t in,
    output logic [$clog2(DATA_WIDTH-1)-1:0] size,
    output logic [DATA_WIDTH-2:0] vli,
    output logic [3:0] zeroNub,
    output logic isDC, valid
);
    typedef struct {
        logic [5:0] value;
        logic reset, add, minus, zero, eq;
    } cnt_t;

    typedef struct {
        logic [DATA_WIDTH-1:0] data;
        logic load, reset;
    } reg_t;

    typedef enum logic{
        DC,
        AC
    } state_t;
    state_t state, state_n;
    logic valid_n, isDC_n;

    always_ff @(posedge clk or negedge rst_n) begin
        state <= !rst_n? DC : state_n;
        valid <= !rst_n? 1'b0 : valid_n;
    end

    always_comb begin
        state_n = state;
        lastDC.load = 0;
        zeroCnt.add = 0;
        zeroCnt.zero = 0;
        valid_n = 0;
        case(state)
            DC: begin  
                if(in.valid) begin
                    valid_n = 1;
                    lastDC.load = 1;
                    state_n = AC;
                end
            end AC: begin
                if(in.valid) begin
                    if(in.data == 0) begin
                        if(zeroCnt.eq) begin
                            valid_n = 1;
                            zeroCnt.zero = 1;
                        end else begin
                            zeroCnt.add = 1;
                        end
                    end else begin
                        valid_n = 1;
                        zeroCnt.zero = 1;
                    end
                end

                if(in.done) begin
                    zeroCnt.zero = 1;
                    state_n = DC;
                    if(!in.valid)
                        valid_n = 0;
                end
            end
        endcase
    end

    cnt_t zeroCnt;
    always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n) 
            zeroCnt.value <= '0;
        else if(zeroCnt.zero)
            zeroCnt.value <= '0;
        else if(zeroCnt.add)
            zeroCnt.value <= zeroCnt.value + 1;
    end
    assign zeroCnt.eq = zeroCnt.value == 15;
    assign zeroNub = zeroCnt.value[3:0];

    reg_t lastDC;
    logic [DATA_WIDTH-1:0] dcDiff;
    always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            lastDC.data <= '0;
        end else begin
            if(lastDC.reset)
                lastDC.data <= '0;
            else if(lastDC.load)
                lastDC.data <= in.data;
        end
    end
    assign dcDiff = in.data - lastDC.data;

    logic [$clog2(DATA_WIDTH-1)-1:0] size_n;
    logic [DATA_WIDTH-2:0] vli_n;
    vliCode #(DATA_WIDTH) vliCoder (
        state == DC ? dcDiff : in.data,
        vli_n, size_n
    );
    always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            vli <= '0;
            size <= '0;
        end else if(valid_n) begin
            isDC <= (state == DC);
            vli <= vli_n;
            size <= size_n;
        end
    end

     
endmodule

module vliCode #(
    parameter DATA_WIDTH = 10
) (
    input logic [DATA_WIDTH-1:0] in,
    output logic [DATA_WIDTH-2:0]  vli,
    output logic [$clog2(DATA_WIDTH-1)-1:0]  size
);
    logic [DATA_WIDTH-2:0] hotOne, reverse, abs;
    always_comb begin
        if(in[DATA_WIDTH-1]) begin
            vli = in[DATA_WIDTH-2:0];
            abs = vli;
        end else begin
            vli = in[DATA_WIDTH-2:0] - 1;
            abs = ~vli;
        end
        for(int i=0; i<DATA_WIDTH-1; i++)
            reverse[i] = abs[DATA_WIDTH-2-i];
        reverse = (~reverse + 1) & reverse;
        for(int i=0; i<DATA_WIDTH-1; i++)
            hotOne[i] = reverse[DATA_WIDTH-2-i];
    end
    encode #(DATA_WIDTH-2) (hotOne, size);

endmodule

module encode #(parameter WIDTH = 10 ) (in, out);
    localparam OUT_W = $clog2(WIDTH);
    input logic [WIDTH-1 : 0] in;
    output logic [OUT_W-1 : 0] out;
    logic [OUT_W-1:0] temp1[WIDTH];
    logic [WIDTH-1:0] temp2[OUT_W];
    generate
        genvar i, j;
        for(i=0; i<WIDTH; i++)
            assign temp1[i] = in[i]? i : 1'b0;
        for(i=0; i<WIDTH; i++)
            for(j=0; j<OUT_W; j++)
                assign temp2[j][i] = temp1[i][j];
        for(i=0; i<OUT_W; i++)
            assign out[i] = | temp2[i];
    endgenerate
endmodule