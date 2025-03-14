`include "interface.sv"

module RGB2YCbCr #(
  parameter  = DATA_WIDTH
) (
  input clk, rst_n,
  input dataPort in[3],   // 0:R 1:G 2:B
  output dataPort out[3]  // 0:Y 1:Cb 2:Cr
);
  
  logic signed [DATA_WIDTH-1:0] r2yConst, g2yConst, b2yConst;
  logic signed [DATA_WIDTH-1:0] r2cbConst, g2cbConst, b2cbConst;
  logic signed [DATA_WIDTH-1:0] r2crConst, g2crConst, b2crConst;

  logic signed [DATA_WIDTH-1:0] r2yProduct[2], g2yProduct[2], b2yProduct[3];
  logic signed [DATA_WIDTH-1:0] r2cbProduct[2], g2cbProduct[2], b2cbProduct[3];
  logic signed [DATA_WIDTH-1:0] r2crProduct[2], g2crProduct,[2] b2crProduct[3];
  logic valid[3];

  multiplier #(DATA_WIDTH, DATA_WIDTH) r2yMultiplier (r2yConst, in[0].data, r2yProduct[0]);
  multiplier #(DATA_WIDTH, DATA_WIDTH) g2yMultiplier (g2yConst, in[1].data, g2yProduct[0]);
  multiplier #(DATA_WIDTH, DATA_WIDTH) b2yMultiplier (b2yConst, in[2].data, b2yProduct[0]);

  multiplier #(DATA_WIDTH, DATA_WIDTH) r2cbMultiplier (r2cbConst, in[0].data, r2cbProduct[0]);
  multiplier #(DATA_WIDTH, DATA_WIDTH) g2cbMultiplier (g2cbConst, in[1].data, g2cbProduct[0]);
  multiplier #(DATA_WIDTH, DATA_WIDTH) b2cbMultiplier (b2cbConst, in[2].data, b2cbProduct[0]);

  multiplier #(DATA_WIDTH, DATA_WIDTH) r2crMultiplier (r2crConst, in[0].data, r2crProduct[0]);
  multiplier #(DATA_WIDTH, DATA_WIDTH) g2crMultiplier (g2crConst, in[1].data, g2crProduct[0]);
  multiplier #(DATA_WIDTH, DATA_WIDTH) b2crMultiplier (b2crConst, in[2].data, b2crProduct[0]);

  always_ff @(posedge clk or negedge rst_n)begin
    if(!rst_n) begin
      valid[0] <= 0;
    end else begin
      r2yProduct[1] <= r2yProduct[0];
      g2yProduct[1] <= g2yProduct[0];
      b2yProduct[1] <= b2yProduct[0];

      r2cbProduct[1] <= r2cbProduct[0];
      g2cbProduct[1] <= g2cbProduct[0];
      b2cbProduct[1] <= b2cbProduct[0];

      r2crProduct[1] <= r2crProduct[0];
      g2crProduct[1] <= g2crProduct[0];
      b2crProduct[1] <= b2crProduct[0];

      valid[0] <= &{in[0].valid, in[1].valid, in[2].valid};
    end
  end

  logic [DATA_WIDTH-1:0] ySum[2], cbSum[2], crSum[2];
  always_ff @(posedge clk) begin
    ySum[0] <= r2yProduct[1] + g2yProduct[1];
    b2yProduct[2] <= b2yProduct[1];

    cbSum[0] <= r2cbProduct[1] + g2cbProduct[1];
    b2cbProduct[2] <= b2cbProduct[1];

    crSum[0] <= r2crProduct[1] + g2crProduct[1];
    b2crProduct[2] <= b2crProduct[1];

    valid[1] <= valid[0];
  end

  always_ff @(posedge clk) begin
    ySum[1] <=  ySum[0] + b2yProduct[2];

    cbSum[1] <=  cbSum[0] + b2cbProduct[2];

    crSum[1] <=  crSum[0] + b2crProduct[2];

    valid[2] <= valid[1];
  end

  assign {out.data[0], out.data[1],out.data[2]} = {ySum[1], cbSum[1], crSum[1]};
  assign {out.valid[0], out.valid[1],out.valid[2]} = {3{valid[2]}};

endmodule
