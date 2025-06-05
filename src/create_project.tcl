set project_name "jpeg_coder"
set project_dir "../project"
set part "xc7z020clg484-1"

set src_dir "./hdl/design"
set constrs_dir "./hdl/constraints"
set sim_dir "./hdl/simulation"

create_project $project_name $project_dir -part $part -force

proc add_src {path} {
    foreach item [glob -nocomplain -directory $path -type {f d} *] {
        if {[file isdirectory $item]} {
            add_src $item
        } elseif {[file extension $item] in {.v .sv}} {
            add_files $item
        }
    }
}

add_src $src_dir
add_files -fileset sim_1 [glob -nocomplain -directory $sim_dir *.sv]
add_files -fileset constrs_1 [glob -nocomplain -directory $constrs_dir *.xdc]

create_ip -name clk_wiz -vendor xilinx.com -library ip -version 6.0 -module_name clk_wiz_0 -dir c:/Users/DELL/Documents/paper/paper/project/jpeg_coder.srcs/sources_1/ip
set_property -dict [list CONFIG.PRIMITIVE {MMCM} CONFIG.PRIM_IN_FREQ {50.000} CONFIG.CLKOUT2_USED {true} CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {50.000} CONFIG.CLKOUT2_REQUESTED_OUT_FREQ {5.000} CONFIG.CLKIN1_JITTER_PS {200.0} CONFIG.CLKOUT1_DRIVES {BUFG} CONFIG.CLKOUT2_DRIVES {BUFG} CONFIG.CLKOUT3_DRIVES {BUFG} CONFIG.CLKOUT4_DRIVES {BUFG} CONFIG.CLKOUT5_DRIVES {BUFG} CONFIG.CLKOUT6_DRIVES {BUFG} CONFIG.CLKOUT7_DRIVES {BUFG} CONFIG.FEEDBACK_SOURCE {FDBK_AUTO} CONFIG.MMCM_BANDWIDTH {OPTIMIZED} CONFIG.MMCM_CLKFBOUT_MULT_F {12.500} CONFIG.MMCM_CLKIN1_PERIOD {20.000} CONFIG.MMCM_CLKIN2_PERIOD {10.0} CONFIG.MMCM_COMPENSATION {ZHOLD} CONFIG.MMCM_CLKOUT0_DIVIDE_F {12.500} CONFIG.MMCM_CLKOUT1_DIVIDE {125} CONFIG.NUM_OUT_CLKS {2} CONFIG.CLKOUT1_JITTER {241.980} CONFIG.CLKOUT1_PHASE_ERROR {150.329} CONFIG.CLKOUT2_JITTER {384.410} CONFIG.CLKOUT2_PHASE_ERROR {150.329}] [get_ips clk_wiz_0]
generate_target {instantiation_template} [get_files "${project_dir}/jpeg_coder.srcs/sources_1/ip/clk_wiz_0/clk_wiz_0.xci"]


