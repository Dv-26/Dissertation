module CdcPulse (
    input logic rst_n,
    input logic inClk,
    input logic in,
    input logic outClk,
    output logic out
);
    logic in2OutSync [3];
    logic out2InSync [2];
    logic inFF;

    always_ff @(posedge outClk or negedge rst_n) begin
        if(!rst_n) begin
            in2OutSync[0] <= 1'b0;
            in2OutSync[1] <= 1'b0;
            in2OutSync[2] <= 1'b0;
        end else begin
            in2OutSync[0] <= inFF;
            in2OutSync[1] <= in2OutSync[0];
            in2OutSync[2] <= in2OutSync[1];
        end
    end

    always_ff @(posedge inClk or negedge rst_n) begin
        if(!rst_n) begin
            out2InSync[0] <= 1'b0;
            out2InSync[1] <= 1'b0;
        end else begin
            out2InSync[0] <= in2OutSync[1];
            out2InSync[1] <= out2InSync[0];
        end
    end

    always_ff @(posedge inClk) begin
        if(!rst_n) begin
            inFF <= 1'b0;
        end else begin
            if(in)
                inFF <= 1'b1;
            else
                if(out2InSync[1])
                    inFF <= 1'b0;
                else
                    inFF <= inFF;
        end
    end
    assign out = in2OutSync[2] & ~in2OutSync[1];
endmodule