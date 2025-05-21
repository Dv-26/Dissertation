`ifndef __UART_H__
`define __UART_H__

interface UartIF #() ();
  (* dont_touch = "true" *)logic [7:0] data;
  (* dont_touch = "true" *)logic valid, ready;
  modport master (
    output data, valid,
    input ready
  );
  modport slave (
    input data, valid,
    output ready
  );
endinterface

`endif
