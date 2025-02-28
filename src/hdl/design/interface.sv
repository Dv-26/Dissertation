`ifndef __INTERFACE__
`define __INTERFACE__
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
  x2zX_t x;
  dctPort_t z;
} x2zPort_t;


typedef struct {
  logic [9:0] data;
  logic load;
} z2yZ_t;

typedef struct {
  z2yZ_t z;
  dctPort_t y;
} z2yPort_t;

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