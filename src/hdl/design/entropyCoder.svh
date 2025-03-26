`ifndef __ENTROPYCODE_H__
`define __ENTROPYCODE_H__

typedef struct packed {
  logic [4:0] size;
  logic [8:0] vli;
  logic [3:0] run;
  logic isDC;
} tempCodeData_t;

typedef struct packed {
  tempCodeData_t data;
  logic valid, done;
} tempCode_t;

typedef struct packed {
  logic [10:0] code;
  logic [2:0] size;
} luminanceDcHuffman_t;

typedef struct packed {
  logic [15:0] code;
  logic [3:0] size;
} luminanceAcHuffman_t;


`endif
