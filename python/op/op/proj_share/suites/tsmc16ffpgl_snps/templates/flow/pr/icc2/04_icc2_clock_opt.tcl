##########################################################################################
# Tool: IC Compiler II
# Alchip Onepiece
# icc2_clock_opt
##########################################################################################
puts "Alchip-info : Running script [info script]\n"

#set pre_stage icc2_clock
#set cur_stage icc2_clock_opt
set pre_stage "{{pre.sub_stage}}"
set cur_stage "{{cur.sub_stage}}"

set pre_stage [lindex [split $pre_stage .] 0]
set cur_stage [lindex [split $cur_stage .] 0]

##mkdir tool output dirctory
set pre_flow_data_dir "{{pre.flow_data_dir}}/{{pre.stage}}"

set BLK_NAME          "{{env.BLK_NAME}}"

set pre_design_library  "$pre_flow_data_dir/${pre_stage}.{{env.BLK_NAME}}.nlib"
set cur_design_library "{{cur.cur_flow_data_dir}}/${cur_stage}.{{env.BLK_NAME}}.nlib"

set clock_opt_cpu_number "{{local.clock_opt_cpu_number}}"
set clock_opt_active_scenario_list "{{local.clock_opt_active_scenario_list}}"

##setup host option

set_host_option -max_core $clock_opt_cpu_number

##back up database
set bak_date [exec date +%m%d]
if {[file exist ${cur_design_library}] } {
if {[file exist ${cur_design_library}_bak_${bak_date}] } {
exec rm -rf ${cur_design_library}_bak_${bak_date}
}
exec mv -f ${cur_design_library} ${cur_design_library}_bak_${bak_date}
}
## copy block and lib from previous stage
copy_lib -from_lib ${pre_design_library} -to_lib ${cur_design_library} -no_design
open_lib ${pre_design_library}
copy_block -from ${pre_design_library}:{{env.BLK_NAME}}/${pre_stage} -to ${cur_design_library}:{{env.BLK_NAME}}/${cur_stage}
close_lib ${pre_design_library}

open_lib ${cur_design_library}

current_block {{env.BLK_NAME}}/${cur_stage}

link_block
save_lib



puts "run icc2_clock_opt"

clock_opt -from final_opto

start_gui
sh sleep 5
stop_gui

write_verilog -compress gzip -exclude {leaf_module_declarations pg_objects} -hierarchy all {{cur.cur_flow_data_dir}}/$cur_stage.{{env.BLK_NAME}}.v

write_verilog -compress gzip -exclude {scalar_wire_declarations leaf_module_declarations empty_modules} -hierarchy all {{cur.cur_flow_data_dir}}/${cur_stage}.{{env.BLK_NAME}}.pg.v

save_block -as {{env.BLK_NAME}}
save_lib
