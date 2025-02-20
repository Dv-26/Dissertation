interface X2zPeRow_if#(parameter DATA_WIDTH = 8)(); 
  logic [DATA_WIDTH-1:0] x;
  logic [DATA_WIDTH-1:0] z;
  logic sumDiffSel;
  logic load;
  logic valid;

  modport rx (
    input x,
    input z,

    input sumDiffSel,
    input load,
    input valid
  );
  modport tx (
    output x,
    output z,

    output sumDiffSel,
    output load,
    output valid
  );
endinterface

interface Z2yPeRow_if #(parameter DATA_WIDTH = 8)();
  logic [DATA_WIDTH-1 : 0] z;
  logic load;
  logic [DATA_WIDTH-1 : 0] y;
  modport rx (
    input z,
    input load,
    input y
  );
  modport tx (
    output z,
    output load,
    output y
  );
endinterface

interface PeCol_if #(parameter DATA_WIDTH = 8)();
  logic  [DATA_WIDTH-1:0]  coefficient;
  modport rx (
    input coefficient
  );
  modport tx (
    output coefficient
  );
endinterface
