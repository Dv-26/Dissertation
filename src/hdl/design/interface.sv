interface PeBusIf#(parameter DATA_WIDTH = 8)(); 
  logic [DATA_WIDTH-1:0] x;
  logic [DATA_WIDTH-1:0] coefficient;
  logic [DATA_WIDTH-1:0] z;
  logic sumDiffSel;
  logic load;
  logic valid;

  modport peRowIn(
    input x,
    input z,

    input sumDiffSel,
    input load,
    input valid
  );

  modport peRowOut(
    output x,
    output coefficient,
    output z,

    output sumDiffSel,
    output load,
    output valid
  );

  modport peColIn(
    input coefficient
  );

  modport peColOut(
    output coefficient
  );
endinterface

