`ifndef __ENTROPYCODE_H__
`define __ENTROPYCODE_H__

package huffman_pkg;

  typedef struct packed {
    logic [3:0] size;
    logic [8:0] vli;
    logic [3:0] run;
    logic isDC;
  } tempCodeData_t;

  typedef struct packed {
    tempCodeData_t data;
    logic valid, done;
  } tempCode_t;

  localparam CODE_W = 32;
  localparam SIZE_W = $clog2(CODE_W);

  typedef struct packed {
    logic [CODE_W-1:0] code;
    logic [SIZE_W-1:0] size;
  } Huffman_t;
endpackage

`endif
