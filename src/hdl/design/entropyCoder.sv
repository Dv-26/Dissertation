`include "interface.sv"

typedef struct {
    logic [4:0] size;
    logic [8:0] vli;
    logic [3:0] zeroNub;
    logic isDC;
} tempCodeData_t;

typedef struct {
    logic [8:0] code;
    logic [2:0] size;
} dcHuffman_t;

typedef struct {
    logic [15:0] code;
    logic [3:0] size;
} acHuffman_t;

typedef struct {
    tempCodeData_t data;
    logic valid, done;
} tempCode_t;

module huffmanCode #(
    parameter DATA_WIDTH = 10,
    parameter LUMINANCE = 1 // 1:亮度 0:色度
) (
    input clk, rst_n,
    input tempCode_t  in,
    output codePort_t out
);
    localparam IN_W = 5 + 9 + 3 + 1;
    logic isZRL, notZRL, isEOB;
    assign isZRL = &{in.valid, !in.isDC , &in.zeroNub};
    assign notZRL = &{in.valid, !isZRL};
    assign isEOB = &{in.done, !in.valid};
    logic bufRst;

    tempCodeData_t ZRLbuf;
    fifoWr_if #(IN_W) bufWr ();
    fifoRd_if #(IN_W) bufRd ();
    ShiftFIFO #(IN_W, 4) InBuf (clk, rst_n, bufRst, bufWr, bufRd);
    assign bufWr.data = {in.data.size, in.data.vli, in.data.zeroNub, in.data.isDC};
    assign {ZRLbuf.size, ZRLbuf.vli, ZRLbuf.zeroNub, ZRLbuf.isDC} = bufRd.data; 

    enum logic {NORMAL, RD_BUF} state, state_n;
    always_ff @(posedge clk, negedge rst_n) 
        state <= !rst_n ? NORMAL : RD_BUF;
    always_comb begin
        state_n = state;
        bufWr.en = 0;
        if(isZRL)
            bufWr.en = 1;
        case(state)
            NORMAL: begin
                if(notZRL && !inBuf.empty) begin
                    bufWr.en = 1;
                    bufRd.en = 1;
                    state_n = RD_BUF;
                end
            end RD_BUF: begin
                bufRd.en = 1;
                if(in.valid)
                    bufWr.en = 1;
                if(inBuf.empty)
                    state_n = NORMAL;
            end
        endcase
    end


endmodule

module tempCoder #(
    parameter DATA_WIDTH = 10
) (
    input clk, rst_n,
    input codePort_t in,
    output tempCode_t out
);
    typedef struct {
        logic [5:0] value;
        logic add, zero, eq;
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
    logic valid_n;

    always_ff @(posedge clk or negedge rst_n) begin
        state <= !rst_n? DC : state_n;
        out.valid <= !rst_n? 1'b0 : valid_n;
    end

    always_comb begin
        state_n = state;
        lastDC.load = 0;
        lastDC.reset = 0;
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

    logic [$clog2(DATA_WIDTH-1):0] size_n;
    logic [DATA_WIDTH-2:0] vli_n;
    vliCode #(DATA_WIDTH) vliCoder (
        state == DC ? dcDiff : in.data,
        vli_n, size_n
    );
    always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            out.data.vli <= '0;
            out.data.size <= '0;
            out.data.isDC <= 0;
            out.data.zeroNub <= '0;
        end else if(valid_n) begin
            out.data.isDC <= (state == DC);
            out.data.vli <= vli_n;
            out.data.size <= size_n;
            out.data.zeroNub <= zeroCnt.value[3:0];
            out.done <= in.done;
        end
    end

endmodule

module vliCode #(
    parameter DATA_WIDTH = 10
) (
    input logic [DATA_WIDTH-1:0] in,
    output logic [DATA_WIDTH-2:0]  vli,
    output logic [$clog2(DATA_WIDTH-1):0]  size
);
    logic [DATA_WIDTH-2:0] hotOne, reverse, abs;
    always_comb begin
        if(in[DATA_WIDTH-1]) begin
            vli = in[DATA_WIDTH-2:0] - 1;
            abs = ~vli;
        end else begin
            vli = in[DATA_WIDTH-2:0];
            abs = vli;
        end
        for(int i=0; i<DATA_WIDTH-1; i++)
            reverse[i] = abs[DATA_WIDTH-2-i];
        reverse = (~reverse + 1) & reverse;
        for(int i=0; i<DATA_WIDTH-1; i++)
            hotOne[i] = reverse[DATA_WIDTH-2-i];
    end
    logic [$clog2(DATA_WIDTH-1)-1:0]  bin;
    encode #(DATA_WIDTH-1) hot2bin (hotOne, bin);
    assign size = |in[DATA_WIDTH-2:0] ? bin + 1 : 0;

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