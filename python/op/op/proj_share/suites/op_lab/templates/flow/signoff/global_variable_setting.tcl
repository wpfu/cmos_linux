##=================================================================================================================================================##
##    ICC2   glob variable setting list                                                                                                            ##
##=================================================================================================================================================##
set signoff_input_dir "/proj/TRAINING/OP_LAB/lab_felix_yuan/WORK/0308/share/templates/flow/signoff/input_file"    ;# Need to be modified according to different projects
#Item: Check  max wire length
set footprint_buf                       "BUF"                                           ;# default common value <>
set footprint_inv                       "INV"                                           ;# default common value <>
set footprint_tie                       "TIE"                                           ;# default common value <>
set wire_length_limitation              "200"                                           ;# default value <> , you can modify it 

#Item: Check  max wire length (signal & clock wire)
#signal wire
set signal_wire_length_limitation       "500"                                           ;# GE-05-05, default value <> , you can modify it 
set output_rpt_signal                   "check_clock_wire_length.rpt"                   ;# GE-05-05, default report's name <> ;you can modify it 
#clock wire 
set clock_wire_length_limitation        "200"                                           ;# GE-05-05, default value <> , you can modify it
set clock_pin_list_file                 "${signoff_input_dir}/clk_pin.list"             ;# GE-05-05, need scan and func scernario's pins,such as {clk_U1/CP clk_U2/CP ...clk_Un/CP}
set output_rpt_clock                    "check_clock_wire_length.rpt"                   ;# GE-05-05, default report's name <> ;you can modify it 

#Item: Check tie fanout and wire length
# fanout
set tie_wire_length_limitation          "100"                                           ;# GE-02-12, default value <> 
set output_rpt_tie                      "check_tie_connection.rpt"                      ;# GE-02-12, default report's name <> ;you can modify it 
#net_length
set tie_cell_type                       "TIE*"                                          ;# GE-02-12, need to set {TIE*/ TIEL* /TIEH*}
set output_rpt_tie_length               "check_tie_net_length.rpt"                      ;# GE-02-12, default report's name <> ;you can modify it
# 1'b0 1'b1
set output_rpt_tie_insertion            "check_tie_insertion.rpt"                       ;# GE-02-04, default report's name <> ;you can modify it

#Item: Check  macro/memory orientation
set mem_ref_names                       "FA1D0BWP16P90CPDULVT XOR3D0BWP16P90CPDULVT"    ;# GE-04-13, such as {TS6N45GSA128X64M2F}
set physical_partition_reference_names  " "                                             ;# GE-04-13, set it to empty when there is no hierachical block/IP 
set mem_orientation_file                "${signoff_input_dir}/allowed_orientation.list" ;# GE-04-13, list all permitted orientation ,such as "R0 R90 R180 R270 MX MXR90 MYR90" 
set output_rpt_mem_orientation          "check_memory_orientation.rpt"                  ;# GE-04-13, default report's name <> ; you can modify it

#Item: Check ip/port isolation 
#ip
#set ip_reference_names                 "${signoff_input_dir}/ip_ref_name.list"          ;# GE-04-07, need to ref_name, such as "DFQD2BWP16P90CPDULVT XOR2D0BWP16P90CPDULVT .."
set ip_reference_names                  "FA1D0BWP16P90CPDULVT XOR3D0BWP16P90CPDULVT"     ;# GE-04-07, default value <> , you can modify it 
set ip_wire_length_limitation           "50"                                             ;# GE-04-07, default value <> , you can modify it 
set output_rpt_ip_isolation             "check_ip_isolation.rpt"                         ;# GE-04-07, default report's name <> ; you can modify it
#port
set ip_reference_names                  "FA1D0BWP16P90CPDULVT XOR3D0BWP16P90CPDULVT"
#set physical_partition_reference_names  "${signoff_input_dir}/black_box_ref_name.list"  ;# GE-04-07, need to ref_name, such as "XOR2D0BWP16P90CPDULVT DFQD2BWP16P90CPDULVT .."
set physical_partition_reference_names  " "                                              ;# GE-04-07, set it to empty when there is no hierachical block/IP 
set port_wire_length_limitation         "50"                                             ;# GE-04-07, default value <> , you can modify it
set output_rpt_port_isolation           "check_port_isolation.rpt"                       ;# GE-04-07, default report's name <> ;you can modify it

#Item: check_power_rail_via , check_power_rail_via < none | -power | -ground >           ;# GE-04-01, 

#Item: check clock NDR rule  , check_nondef_route < none | -net (net_name|net_file_name) | -clock clock_file_name >
set net_file_name                       "clock_net.list"                                 ;# CK-02-03, default value <>; you can modify it
set clock_file_name                     "clock_cell.list"                                ;# CK-02-03, default value <>; you can modify it

#Item: Check delay cell chain
set delay_cell_type                     "ref_name=~DEL*"                                 ;# delay cell's ref_name,
set output_rpt_delay_cell_chain         "check_delay_cell_chain.rpt"                     ;# default report's name <> ; you can modify it

#Item: Check open input pin
set output_rpt_open_pin                 "check_open_input_pin.rpt"                       ;# GE-02-02, default report's name <> ; you can modify it


#Item: Check filler / dcap / eco cells
set filler_cell_type                    "ref_name =~ FILL*"                              ;# GE-04-20, filler cell's ref_name
set output_rpt_filler                   "check_filler_area_number.rpt"                   ;# GE-04-20, default report's name <> ; you can modify it 
set dcap_cell_type                      "ref_name =~ DCAP*"                              ;# GE-04-02, dcap cell's ref_name
set output_rpt_dcap                     "check_dcaps_area_number.rpt"                    ;# GE-04-02, default report's name <> ; you can modify it 
set eco_cell_type                       "ref_name =~ GDCAP*"                             ;# GE-04-03, ECO cell's ref_name
set output_rpt_eco                      "check_eco_area_number.rpt"                      ;# GE-04-03, default report's name <> ; you can modify it 

#Item: check clock cells enclosed by dcap cells                                          
set check_clock_decap_file              "${signoff_input_dir}/clock_cell_nets.list"      ;# GE-04-08, checking if the decap cells were enclosed by the clock cells,such as {CTS_u1 \n CTS_u2 \n ...}.

#Item: Check keep cell and keep nets
#keep_cell_list   
set size_only_cell                      "${signoff_input_dir}/size_only_cell.list"       ;# GE-02-[06,07], list size only cells,such as {i_instance_1 i_instance_2 ... i_instance_n } 
#keep_net_list               
set dont_touch_nets                     "${signoff_input_dir}/dont_touch_nets.list"      ;# GE-02-08, list dont touch nets,such as {FPGA_CLK IO_CLK AHB0_CLK FPGA_RSTN ... }


##=================================================================================================================================================##
##    PrimeTime   glob variable setting list                                                                                                       ##
##=================================================================================================================================================##

#Item:check multi-driver
set output_rpt_multi_driver             "check_multi_driver.rpt"                         ;# GE-02-03, default report's name <> ;you can modify it
#Item:check multi-drive net 
set output_rpt_multi_drive_net          "check_multi_drive_net.rpt"                      ;# CK-01-16, default report's name <> ;you can modify it
#Item:check multi-drive cell 
set output_rpt_multi_cell_type          "check_multi_drive_cell_type.rpt"                ;# CK-01-16, default report's name <> ;you can modify it

#Item:check dont use cell 
set output_rpt_dont_use_cell            "check_dont_use_cell.rpt"                        ;# GE-02-15, default report's name <> ;you can modify it

#Item:check open input pin 
set output_rpt_open                     "check_open_input_pin.rpt"                       ;# GE-02-02, default report's name <> ;you can modify it

#Item:check dont touch net 
set output_rpt_dont_touch_net           "check_dont_touch_net.rpt"                       ;# GE-02-08, default rptort's name <> ;you can modify it

#Item:check size only cell 
set output_rpt_size_only_cell           "check_size_only_cell.rpt"                       ;# GE-02-[06,07], default report's name <> ;you can modify it

#Item:check clock Xtalk noise delay penalty
set clock_threshold                     "0.02"                                           ;# GE-06-[03,05], default value is 0.02<20ps>;you can modify it 
set output_rpt_clock_pt                 "check_clock_net_xtalk_delta_delay.rpt"          ;# GE-06-[03,05], default report's name <> ;you can modify it

#Item:check signal Xtalk noise delay penalty
set signal_threshold                    "0.02"                                           ;# GE-06-[02,04], default value is 0.02<20ps>;you can modify it 
set output_rpt_signal_pt                "check_signal_net_xtalk_delta_delay.rpt"         ;# GE-06-[02,04], default report's name <> ;you can modify it

#Item: check ip clock duty cycle
#set ip_clock_duty_spec_file             "${signoff_input_dir}/ip_clock_duty_spec.list"  ;# CK-01-19, Format: clock_pin   period  min_duty  max_duty 
set ip_clock_duty_spec_file             "i_instance_1/CP 20.000000 0.49 0.51"            ;# CK-01-19, Example: u_ddr/CLK  2.500000  0.49      0.51
set pt_cmd_file                         "set_min_pulse_width.tcl"                        ;# CK-01-19, output pt cmd script file
set output_rpt_ip_duty                  "check_ip_duty.rpt"                              ;# CK-01-19, default report's name <> ;you can modify it

#Item: report clock cell type
set high_vth_cell_ref_name              "*HVT"                                           ;# CK-01-03, default <> ;need to list matching keywords          
set low_drive_cell_ref_name             "*D[01]HVT"                                      ;# CK-01-03, default <> ;need to list matching keywords          
set output_rpt_clock_cell               "report_clock_cell_type.rpt"                     ;# CK-01-03, default report's name <> ;you can modify it

#Item: report clock summary                                                              ;# CK-01-[10,11]


##=================================================================================================================================================##
##    Perl   glob variable setting list                                                                                                            ##
##=================================================================================================================================================##

#Item: check GDS layer information of Virtuoso(R) XStream Out
set top_dir                             "${signoff_input_dir}/perl/chip"                 ;# default is absolute path, relative path is also support.
set sc_dir                              "${signoff_input_dir}/perl/SC"                   ;# default is absolute path, relative path is also support.
set mem_dir                             "${signoff_input_dir}/perl/MEM"                  ;# default is absolute path, relative path is also support.
set io_dir                              "${signoff_input_dir}/perl/IO"                   ;# default is absolute path, relative path is also support.
set ip_dir                              "${signoff_input_dir}/perl/IP"                   ;# default is absolute path, relative path is also support.

#Item: check the bus order in IP's cdl
set path_cdl                            "${signoff_input_dir}/perl/IP.cdl"               ;# default is absolute path, relative path is also support.

#Item: check netlist
#set netlists_1                         [glob {{env.PROJ_SHARE_TMP}}/${dst_stage}/${op4_dst_eco}/netlists_1/*.v]     ;# default is absolute path, relative path is also support.

#set netlists_1                          [glob ${signoff_input_dir}/perl/netlists_1/*.v]  ;# default is absolute path, relative path is also support.
set netlist_1                           "${signoff_input_dir}/perl/Netlist_1.v"          ;# default is absolute path, relative path is also support.
#set netlists_2                          [glob ${signoff_input_dir}/perl/netlists_2/*.v]  ;# default is absolute path, relative path is also support.
set netlist_2                           "${signoff_input_dir}/perl/Netlist_2.v"          ;# default is absolute path, relative path is also support.
#set netlists_3                          [glob ${signoff_input_dir}/perl/netlists_3/*.v]  ;# default is absolute path, relative path is also support.
set netlist_3                           "${signoff_input_dir}/perl/Netlist_3.v"          ;# default is absolute path, relative path is also support.

##=================================================================================================================================================##
##    Innovus   glob variable setting list                                                                                                       ##
##=================================================================================================================================================##

##=================================================================================================================================================##
##    shell   glob variable setting list                                                                                                       ##
##=================================================================================================================================================##
