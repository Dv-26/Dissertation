set part "xc7z020clg484-1"

synth_design -top top -part $part

create_debug_core u_ila_0 ila

set_property C_DATA_DEPTH 4096 [get_debug_cores u_ila_0]
set_property C_TRIGIN_EN false [get_debug_cores u_ila_0]
set_property C_TRIGOUT_EN false [get_debug_cores u_ila_0]
set_property C_ADV_TRIGGER false [get_debug_cores u_ila_0]
set_property C_INPUT_PIPE_STAGES 0 [get_debug_cores u_ila_0]
set_property C_EN_STRG_QUAL false [get_debug_cores u_ila_0]
set_property ALL_PROBE_SAME_MU true [get_debug_cores u_ila_0]
set_property ALL_PROBE_SAME_MU_CNT 1 [get_debug_cores u_ila_0]
startgroup 
set_property C_EN_STRG_QUAL true [get_debug_cores u_ila_0 ]
set_property C_ADV_TRIGGER true [get_debug_cores u_ila_0 ]
set_property ALL_PROBE_SAME_MU true [get_debug_cores u_ila_0 ]
set_property ALL_PROBE_SAME_MU_CNT 4 [get_debug_cores u_ila_0 ]
endgroup
connect_debug_port u_ila_0/clk [get_nets [list pll/inst/clk_out1 ]]
set_property port_width 2 [get_debug_ports u_ila_0/probe0]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe0]
connect_debug_port u_ila_0/probe0 [get_nets [list {coder/pingpong/rdState[0]} {coder/pingpong/rdState[1]} ]]
create_debug_port u_ila_0 probe
set_property port_width 2 [get_debug_ports u_ila_0/probe1]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe1]
connect_debug_port u_ila_0/probe1 [get_nets [list {coder/pingpong/rdState_n[0]} {coder/pingpong/rdState_n[1]} ]]
create_debug_port u_ila_0 probe
set_property port_width 64 [get_debug_ports u_ila_0/probe2]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe2]
connect_debug_port u_ila_0/probe2 [get_nets [list {coderOut[data][code][0]} {coderOut[data][code][1]} {coderOut[data][code][2]} {coderOut[data][code][3]} {coderOut[data][code][4]} {coderOut[data][code][5]} {coderOut[data][code][6]} {coderOut[data][code][7]} {coderOut[data][code][8]} {coderOut[data][code][9]} {coderOut[data][code][10]} {coderOut[data][code][11]} {coderOut[data][code][12]} {coderOut[data][code][13]} {coderOut[data][code][14]} {coderOut[data][code][15]} {coderOut[data][code][16]} {coderOut[data][code][17]} {coderOut[data][code][18]} {coderOut[data][code][19]} {coderOut[data][code][20]} {coderOut[data][code][21]} {coderOut[data][code][22]} {coderOut[data][code][23]} {coderOut[data][code][24]} {coderOut[data][code][25]} {coderOut[data][code][26]} {coderOut[data][code][27]} {coderOut[data][code][28]} {coderOut[data][code][29]} {coderOut[data][code][30]} {coderOut[data][code][31]} {coderOut[data][code][32]} {coderOut[data][code][33]} {coderOut[data][code][34]} {coderOut[data][code][35]} {coderOut[data][code][36]} {coderOut[data][code][37]} {coderOut[data][code][38]} {coderOut[data][code][39]} {coderOut[data][code][40]} {coderOut[data][code][41]} {coderOut[data][code][42]} {coderOut[data][code][43]} {coderOut[data][code][44]} {coderOut[data][code][45]} {coderOut[data][code][46]} {coderOut[data][code][47]} {coderOut[data][code][48]} {coderOut[data][code][49]} {coderOut[data][code][50]} {coderOut[data][code][51]} {coderOut[data][code][52]} {coderOut[data][code][53]} {coderOut[data][code][54]} {coderOut[data][code][55]} {coderOut[data][code][56]} {coderOut[data][code][57]} {coderOut[data][code][58]} {coderOut[data][code][59]} {coderOut[data][code][60]} {coderOut[data][code][61]} {coderOut[data][code][62]} {coderOut[data][code][63]} ]]
create_debug_port u_ila_0 probe
set_property port_width 7 [get_debug_ports u_ila_0/probe3]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe3]
connect_debug_port u_ila_0/probe3 [get_nets [list {coderOut[data][size][0]} {coderOut[data][size][1]} {coderOut[data][size][2]} {coderOut[data][size][3]} {coderOut[data][size][4]} {coderOut[data][size][5]} {coderOut[data][size][6]} ]]
create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe4]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe4]
connect_debug_port u_ila_0/probe4 [get_nets [list {coderOut[done]} ]]
create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe5]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe5]
connect_debug_port u_ila_0/probe5 [get_nets [list {coderOut[eop]} ]]
create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe6]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe6]
connect_debug_port u_ila_0/probe6 [get_nets [list {coderOut[sop]} ]]
create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe7]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe7]
connect_debug_port u_ila_0/probe7 [get_nets [list {coderOut[valid]} ]]
create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe8]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe8]
connect_debug_port u_ila_0/probe8 [get_nets [list inClk ]]
create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe9]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe9]
connect_debug_port u_ila_0/probe9 [get_nets [list rx_IBUF ]]
create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe10]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe10]
connect_debug_port u_ila_0/probe10 [get_nets [list tx_OBUF ]]