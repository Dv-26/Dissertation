`ifndef __INTERFACE__
`define __INTERFACE__

interface ramWr_if #(
  parameter DATA_WIDTH = 10,
  parameter DEPTH = 8
) (input wire clk);
  logic [DATA_WIDTH-1:0] data;
  logic [$clog2(DEPTH)-1:0] addr;
  logic en;
  modport Tx (
    input  clk,
    output addr,
    output en,
    output data
  );
  modport Rx (
    input clk,
    input addr,
    input en,
    input data
  );
endinterface

interface ramRd_if #(
  parameter DATA_WIDTH = 10,
  parameter DEPTH = 8
) (input wire clk);
  logic [DATA_WIDTH-1:0] data;
  logic [$clog2(DEPTH)-1:0] addr;
  logic en;
  modport Rx (
    input  clk,
    output addr,
    output en,
    input data
  );
  modport Tx (
    input clk,
    input addr,
    input en,
    output data
  );
endinterface

interface fifoRd_if #(
  parameter DATA_WIDTH = 10
) (input wire clk);
  logic [DATA_WIDTH-1:0] data;
  logic en, empty; 
  modport asyncTx (
    input clk,
    input en,
    output data,
    output empty
  );
  modport asyncRx (
    input clk,
    output en,
    input data,
    output empty
  );
  modport syncTx (
    input en,
    output data,
    output empty
  );
  modport syncRx (
    output en,
    input data,
    output empty
  );
endinterface

interface fifoWr_if #(
  parameter DATA_WIDTH = 10
) (input wire clk);
  logic [DATA_WIDTH-1:0] data;
  logic en, full; 
  modport asyncTx (
    input clk,
    output en,
    output data,
    output full
  );
  modport asyncRx (
    input clk,
    input en,
    input data,
    output full
  );
  modport syncTx (
    output en,
    output data,
    output full
  );
  modport syncRx (
    input en,
    input data,
    output full
  );
endinterface

interface rom_if #(
  parameter DATA_WIDTH = 10,
  parameter DEPTH = 8
) ();
  logic [DATA_WIDTH-1:0] data;
  logic [$clog2(DEPTH)-1:0] addr;
  logic en;
  modport rx (
    output addr,
    output en,
    input data
  );
  modport tx (
    input addr,
    input en,
    output data
  );
endinterface

typedef struct packed {
  logic [11:0] data;
  logic sop, eop;
  logic valid;
} dctPort_t;

typedef struct packed {
  logic [23:0] data;
  logic sop, eop;
  logic valid;
} dataPort_t;

typedef struct packed {
  logic [11:0] data;
  logic sop, eop;
  logic valid;
  logic done;
} codePort_t;

`endif
