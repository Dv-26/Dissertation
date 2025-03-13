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

typedef struct {
  logic [9:0] data;
  logic sumDiffSel;
  logic load;
} x2zX_t;

typedef struct {
  logic [9:0] data;
  logic valid;
} dctPort_t;

typedef struct {
  logic [23:0] data;
  logic valid;
} dataPort_t;

typedef struct {
  logic [9:0] data;
  logic load;
} in_t;

typedef struct {
  logic [9:0] data;
  logic valid;
} result_t;

typedef struct {
  in_t in;
  result_t result;
} peRowPort_t;

typedef struct {
  logic [9:0] data;
}peColPort_t;
`endif
