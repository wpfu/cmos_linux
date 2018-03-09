##########################################################################################
# Script: mcmm_setup
##########################################################################################

puts "Alchip-info : Start MCMM setup\n"

remove_scenarios -all
remove_modes -all
remove_corners -all

##########################################################################################
#                                   !WARNING!                                           ##
# YOU NEEED FILL BELLOW WITH YOUR MODE/CONER NAME                                       ##
##########################################################################################

#################################################################################################################################################################################
#                                   !WARNING!                                                                                                                                  ##
# YOU NEEED FILL BELLOW TABLE ACCORDING TO SCENARIO NUMBER                                                                                                                     ## 
# Example                                                                                                                                                                      ##
#set tech_ndm                          "tech_only";#fill tech_ndm name, example tech_only                                                                                      ##
#set scenario_list                     "func.tt0p8v.wcl.cworst_CCworst_T_m40c.setup   func.tt0p8v.wcl.cworst_CCworst_T_m40c.setup  func.tt0p8v.wcl.cworst_CCworst_T_m40c.setup ##
#set process_list                      "1                                1                  1"                                                                                 ##
#set scenario_status_leakage_power     "true                             false             false"                                                                              ## 
#set scenario_status_dynamic_power     "false                            true              false"                                                                              ##
#set scenario_status_max_transition    "true                             true              false"                                                                              ## 
#set scenario_status_max_capacitance   "true                             true              false"                                                                              ##
#set voltage_list                     "{VDD-0.9 VSS-0.0 VDDH-1.16}  {VDD-0.8 VSS-0.0 VDDH-1.16}  {VDD-0.9 VSS-0.0 VDDH-0.95}"                                                  ##
#################################################################################################################################################################################
#####################################################################################################################
#   Timing derate example                                                                                           #  
#                                                                                                                   #
#set timing_derate_lib_corner_list           "ss125c              ff125c"                                                #
#set data_net_early_derate_list          "0.9                0.9"                                                   # 
#set data_net_late_derate_list          "{}                1.1"                                                     #
#set clock_net_early_derate_list         "0.9                {}"                                                    # 
#set clock_net_late_derate_list          "{}                1.1"                                                    #
#set data_cell_early_derate_list          "0.9                0.9"                                                  # 
#set data_cell_late_derate_list          "{}                1.1"                                                    #
#set clock_cell_early_derate_list         "0.9                {}"                                                   # 
#set clock_cell_late_derate_list          "{}                1.1"                                                   #
#set mem_early_derate_list               "0.9                 {}"                                                   #
#set mem_late_derate_list                 "{}                1.1"                                                   # 
#set mem_list                      "{ss_mem_lib/mem_1 ss_mem_lib/mem_2} {ff_mem_lib/mem_1 ff_mem_lib/mem_2}"        #
#####################################################################################################################
##some memory or std lib cell may need timing derate

## scenario settings
set tech_ndm                           "tech_only";# *fill tech_ndm name, example tech_only,remember it's not tech ndm library path! only tech ndm name is OK.
set scenario_list                      "func.tt0p8v.wcl.cworst_CCworst_T_n40c.setup";# *fill scenario table 
set process_list                       "1";# *fill process table, example 1 0.9
set process_label_list                 "";#optional,fill process label table, example fast slow
set scenario_status_leakage_power      "false";#optional,fill setup table with true/false
set scenario_status_dynamic_power      "false";#optional,fill setup table with true/false
set scenario_status_max_transition     "true";#optional,fill setup table with true/false
set scenario_status_max_capacitance    "true";#optional,fill setup table with true/false
set voltage_list                       "{VDD-0.72 VSS-0.0}";# *fill voltage1 table, example "{VDD-0.9 VSS-0.0 VDDH-1.16}"

###timing derate settings
set timing_derate_lib_corner_list     "wcl" ;# *fill with corner names, example ss125c 
set data_net_early_derate_list    "0.93" ;# optional,data net early derate for each corner
set data_net_late_derate_list     "1.07" ;# optional,data net late derate for each corner
set clock_net_early_derate_list   "0.93" ;# optional,clock net early derate for each corner
set clock_net_late_derate_list    "1.07" ;# optional,clock net late derate for each corner
##If your design is does not have aocv/pocv table, you can specify bellow table for clock/data path cell derating
##If your design use aocv/pocv table, then you just leave bellow empty
set data_cell_early_derate_list   "" ;# optional, early derate for data path cells
set data_cell_late_derate_list    "" ;# optional, late derate for data path cells
set clock_cell_early_derate_list  "" ;# optional, early derate for clock path cells
set clock_cell_late_derate_list   "" ;# optional, late derate for data path cells

##some memory cell may need timing derate
set mem_list                      "" ;# optional, memory's lib cells for derate, example */*RAM64x128*
set mem_early_derate_list         "" ;# optional, early derate for listed memories
set mem_late_derate_list          "" ;# optional, late derate for listed memories

###############################################
##No need touch bellow                       ##
###############################################
set i_mcmm 0

foreach scenario $scenario_list {
  set mode                       [ lindex [ split $scenario "." ] 0 ]
  set lib_tt_volt                [ lindex [ split $scenario "." ] 1 ]
  set lib_corner                 [ lindex [ split $scenario "." ] 2 ]
  set rc_corner_tmp              [ lindex [ split $scenario "." ] 3 ]
  set analysis_type              [ lindex [ split $scenario "." ] 4 ]
  set procs                      [lindex $process_list $i_mcmm]
  set procs_l                    [lindex $process_label_list $i_mcmm]
  set volt                       [lindex $voltage_list $i_mcmm]
  set status_leakage_power       [lindex $scenario_status_leakage_power $i_mcmm]
  set status_dynamic_power       [lindex $scenario_status_dynamic_power $i_mcmm]
  set status_max_transition      [lindex $scenario_status_max_transition $i_mcmm]
  set status_max_capacitance     [lindex $scenario_status_max_capacitance $i_mcmm]

  ## catch rc_corner element
  set rc_corner_elements "[split $rc_corner_tmp "_"]"
  set origin_temp                [lindex $rc_corner_elements end]
  set rc_corner_length    [llength $rc_corner_elements]
  set pre_rc_corner_tmp  ""
  set rc_corner ""
  if {$rc_corner_length == 2} {set rc_corner [lindex $rc_corner_elements end-1]}
  while {$rc_corner_length > 1} {
  set rc_corner_length [expr $rc_corner_length - 1]
  set rc_corner [lindex $rc_corner_elements end-$rc_corner_length]
  if {$pre_rc_corner_tmp != ""} {set rc_corner [join "$pre_rc_corner_tmp $rc_corner"  "_"]}
  set pre_rc_corner_tmp $rc_corner
  }

  ## create scenario 
  echo "INFO: $mode $lib_tt_volt $lib_corner $rc_corner $analysis_type"
  if { [ sizeof_coll [ get_modes $mode -quiet ] ] == 0 } {create_mode $mode}
  if { [ sizeof_coll [ get_corners $lib_corner -quiet ] ] == 0 } {create_corner $lib_corner}
  create_scenario -mode $mode -corner $lib_corner -name $scenario
  current_scenario $scenario
 
 ## set scenario status 
  echo "INFO: Setting scenario $scenario anaysis status"
  echo "$i_mcmm"
  
  set set_scenario_status_command "set_scenario_status $scenario"
  if {$analysis_type == "setup"        } {append set_scenario_status_command "-setup true"} 
  if {$analysis_type == "hold"         } {append set_scenario_status_command "-hold true" } 
  if {$status_leakage_power == "true"  } {append set_scenario_status_command "-leakage_power true"}
  if {$status_dynamic_power == "true"  } {append set_scenario_status_command "-dynamic_power true"}
  if {$status_max_transition == "true" } {append set_scenario_status_command "-max_transition true"}
  if {$status_max_capacitance == "true"} {append set_scenario_status_command "-max_capacitance true"}
  
  puts "scenario status: $set_scenario_status_command"

  ## set parasitics
  echo "INFO: set additional MCMM constraint in ICCII"
  
  #set global_max_transition         [lindex $global_max_transition_list $i_mcmm]
  #set global_max_capacitance        [lindex $global_max_capacitance_list $i_mcmm]
  #set cts_max_transition            [lindex $cts_max_transition_list $i_mcmm]
  #set cts_max_capacitance           [lindex $cts_max_capacitance_list $i_mcmm]
  #set data_max_transition           [lindex $data_max_transition_list $i_mcmm]
  #set data_max_capacitance          [lindex $data_max_capacitance_list $i_mcmm]
  
  ## set temprature  
  set temp ""
  set s_length [string length $origin_temp]
  while {$s_length > 1} {
  set s_length [expr $s_length -1]
  set temp_element [string index $origin_temp end-$s_length]
  if {$temp_element == "m"} { set temp_element  "-" }
  if {$temp == ""} { set temp $temp_element} else {set temp [append temp $temp_element ]}
  }
  
puts "INFO: Setting temprature $temp"
  if {$temp != ""} {set_temperature $temp} else {puts "Warning: Temprature for scenario $scenario is not set, please fill temprature list table"}

  ## set process  
puts "INFO: Setting process $procs"

  if {$procs != ""} {set_process_number    $procs } else {puts "Information: Process for scenario $scenario is not set, please fill process list table"
  }
  ## set process label 
puts "INFO: Setting process label $procs_l"
  if {$procs_l != ""} {set_process_label    $procs_l } else {puts "Information: Process for scenario $scenario is not set, please fill process label list table"}

  ## set voltage
puts "INFO: Setting voltage $volt"
  
  foreach volt_l $volt {
  
  if {$volt_l != ""} {
  set voltage_name  [ lindex [ split $volt_l "-" ] 0 ]
  set voltage_value [ lindex [ split $volt_l "-" ] 1 ]
  set_voltage $voltage_value -object_list $voltage_name
  } else {
  puts "Warning: Voltage $voltage_name for scenario $scenario is not set, please fill voltage list table"
  }
  }
  
  ## read tluplus
  set early_tlu_name             $rc_corner
  set late_tlu_name              $rc_corner 
puts "INFO: Reading tlupus for lib_corner $lib_corner"
  set_parasitic_parameters -corners $lib_corner -late_spec $late_tlu_name -early_spec $early_tlu_name -library $tech_ndm
  
  ##read sdc/aocv/pocv
  set sdc_file_name  "${BLK_SDC_DIR}/$BLK_NAME.$mode.sdc"

  if {$OCV_MODE == "aocv"} {set aocv_file_name [set [join "AOCV [string toupper $lib_tt_volt]  [string toupper $lib_corner]" "_"]]} else {set aocv_file_name ""}
  if {$OCV_MODE == "pocv"} {set pocv_file_name [set [join "POCV [string toupper $lib_tt_volt]  [string toupper $lib_corner]" "_"]]} else {set pocv_file_name ""}

  if { [file exist $sdc_file_name] } {
  echo "INFO: source sdc file $sdc_file_name for scenario $scenario"
  source -e -v $sdc_file_name
  } else {
  echo "Warning: sdc file for scenario $scenario doe not exist, please check sdc file $sdc_file_name "
  }  
  
  if {$OCV_MODE == "aocv"} {
  echo "INFO: source aocv file $aocv_file_name for scenario $scenario"
  read_ocvm -corners $lib_corner  "$aocv_file_name"
  } else {
  echo "Information: aocv file for scenario $scenario doe not exist, or aocv mode is not eanble, current mode is $OCV_MODE"
  }

  if {$OCV_MODE == "pocv"} {
  echo "INFO: source pocv file $pocv_file_name for scenario $scenario"
  read_ocvm -corners $lib_corner "$pocv_file_name"
  } else {
  echo "Information: pocv file for scenario $scenario doe not exist, or pocv mode is not eanble, current mode is $OCV_MODE"
  }

  ##max capacitance/max transition
#  echo "INFO: set max capacitance/max transition for current scenario $scenario"
  
#  if {$global_max_capacitance != ""} {
#  set_max_capacitance $global_max_capacitance [current_design]
#  }
#  if {$global_max_transition != ""} {
#  set_max_transition $global_max_transition [current_design]
#  }
#  if {$data_max_capacitance != ""} {
#  set_max_capacitance -data_path $data_max_capacitance [all_clocks]
#  }
#  if {$data_max_transition != ""} {
#  set_max_transition -data_path $data_max_transition [all_clocks]
#  }
#  if {$cts_max_capacitance != ""} {
#  set_max_capacitance -clock_path $cts_max_capacitance [all_clocks]
#  }
#  if {$cts_max_transition != ""} {
#  set_max_transition -clock_path $cts_max_transition [all_clocks]
#  }
  incr i_mcmm
  echo "$i_mcmm"
}

##########################################
##   Completed MCMM setup               ##
##########################################

puts "Alchip-info : Completed MCMM setup\n"

foreach_in_collection mode [all_modes] {
	current_mode $mode
	remove_propagated_clocks [all_clocks]
	remove_propagated_clocks [get_ports]
	remove_propagated_clocks [get_pins -hierarchical]
}
current_mode 

report_mode

##########################################
##   Completed MCMM setup               ##
##########################################

##########################################
#   Start timing dereate                 #
##########################################

set i_derate 0

if {$timing_derate_lib_corner_list != ""} { 

foreach corner $timing_derate_lib_corner_list { 

puts "Information: $i_derate current corner is $corner"

if {$data_net_early_derate_list != ""} {
set data_net_early_derate [lindex $data_net_early_derate_list $i_derate]
} else {
set data_net_early_derate ""
}

if {$data_net_late_derate_list != ""} {
set data_net_late_derate  [lindex $data_net_late_derate_list $i_derate]
} else {
set data_net_late_derate  ""
}

if {$clock_net_early_derate_list != ""} { 
set clock_net_early_derate [lindex $clock_net_early_derate_list $i_derate]
} else {
set clock_net_early_derate  ""
}

if {$clock_net_late_derate_list != ""} { 
set clock_net_late_derate  [lindex $clock_net_late_derate_list $i_derate]
} else {
set clock_net_late_derate  ""
}

if {$data_cell_early_derate_list != ""} {
set data_cell_early_derate [lindex $data_cell_early_derate_list $i_derate]
} else {
set data_cell_early_derate  ""
}

if {$data_cell_late_derate_list != ""} {
set data_cell_late_derate  [lindex $data_cell_late_derate_list $i_derate]
} else {
set data_cell_late_derate  ""
}

if {$clock_cell_early_derate_list != ""} { 
set clock_cell_early_derate [lindex $clock_cell_early_derate_list $i_derate]
} else {
set clock_cell_early_derate  ""
}

if {$clock_cell_late_derate_list != ""} { 
set clock_cell_late_derate  [lindex $clock_cell_late_derate_list $i_derate]
} else {
set clock_cell_late_derate  ""
}

if {$mem_early_derate_list != ""} {
set mem_early_derate [lindex $mem_early_derate_list $i_derate]
} else {
set mem_early_derate  ""
}

if {$mem_late_derate_list != ""} {
set mem_late_derate  [lindex $mem_late_derate_list $i_derate]
} else {
set mem_late_derate_list  ""
}

if {$mem_list != ""} {
set mem              [lindex $mem_list $i_derate]
} else {
set mem  ""
}

if {$data_net_early_derate != ""} {
set_timing_derate -data -net_delay -early $data_net_early_derate -corners $corner
}
if {$data_net_late_derate != ""} {
set_timing_derate -data -net_delay -late $data_net_late_derate -corners $corner
}
if {$clock_net_early_derate != ""} {
set_timing_derate -clock -net_delay -early $clock_net_early_derate -corners $corner
}
if {$clock_net_late_derate != ""} {
set_timing_derate -clock -net_delay -late $clock_net_late_derate -corners $corner
}
if {$data_cell_early_derate != ""} {
set_timing_derate -data -cell_delay -early $data_cell_early_derate -corners $corner
}
if {$data_cell_late_derate != ""} {
set_timing_derate -data -cell_delay -late $data_cell_late_derate -corners $corner
}
if {$clock_cell_early_derate != ""} {
set_timing_derate -clock -cell_delay -early $clock_cell_early_derate -corners $corner
}
if {$clock_cell_late_derate != ""} {
set_timing_derate -clock -cell_delay -late $clock_cell_late_derate -corners $corner
}

if {$mem != ""} {
 if {$mem_early_derate != ""} {
 set_timing_derate  -early $mem_early_derate [get_lib_cell "$mem"] -corners $corner
 }
 if {$mem_late_derate != ""} {
 set_timing_derate  -late $mem_late_derate [get_lib_cell "$mem"] -corners $corner
 }
 }

 incr i_derate
 puts "Information: $i_derate current corner $corner has finish timing derate setting"

 }
 } else {
 puts "Information:core list $timing_derate_lib_corner_list is empty for additional timing derate"
 }
##########################################
##   Completed Timing derate            ##
##########################################

puts "Alchip-info : Completed Timing derate setting\n"

