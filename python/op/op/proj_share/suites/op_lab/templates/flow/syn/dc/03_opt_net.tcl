#$# --> write_def -output $cur_flow_data_dir/04_xm_cpu.def -version 5.6 -nondefault_rule
#$# --> write_parasitics -output  $cur_flow_data_dir/04_xm_cpu.spef -format reduced

#===================================================================
#=================== opt net1 ======================================
#===================================================================
optimize_netlist -area
source -e {{cur.config_plugins_dir}}/dc_scripts/change_name.tcl
write -hier -format verilog -out $cur_flow_data_dir/05_${TOP}.v
write -f ddc -h -out $cur_flow_data_dir/05_${TOP}.ddc

report_timing -nets -input_pins -nosplit -significant_digits 3 -max_paths 100000 -slack_lesser_than 0 -nworst 1 -delay max > $cur_flow_rpt_dir/05_SYN_{{local.lib_corner}}.rpt
sh /usr/bin/perl {{cur.config_plugins_dir}}/dc_scripts/check_violation_summary.pl $cur_flow_rpt_dir/05_SYN_{{local.lib_corner}}.rpt > $cur_flow_rpt_dir/05_SYN_{{local.lib_corner}}.sum
proc_qor > $cur_flow_rpt_dir/05_proc_qor.rpt
report_qor > $cur_flow_rpt_dir/05_qor.rpt
report_power > $cur_flow_rpt_dir/05_power.rpt
#source -e -v /proj/7nm_evl/WORK/dong/7nm/xm_cpu/DCG/fp_05/check_7nm.tcl
#check_cell_area > $cur_flow_rpt_dir/05_vt_ratio.tcl

write_icc2_files -force -output $cur_flow_data_dir/icc2_05

#===================================================================
#=================== opt net2 ======================================
#===================================================================
optimize_netlist -area
source -e {{cur.config_plugins_dir}}/dc_scripts/change_name.tcl
set_svf -off
write -hier -format verilog -out $cur_flow_data_dir/${TOP}.v
write -f ddc -h -out $cur_flow_data_dir/06_${TOP}.ddc

report_timing -nets -input_pins -nosplit -significant_digits 3 -max_paths 100000 -slack_lesser_than 0 -nworst 1 -delay max > $cur_flow_rpt_dir/06_SYN_{{local.lib_corner}}.rpt
sh /usr/bin/perl {{cur.config_plugins_dir}}/dc_scripts/check_violation_summary.pl $cur_flow_rpt_dir/06_SYN_{{local.lib_corner}}.rpt > $cur_flow_rpt_dir/06_SYN_{{local.lib_corner}}.sum
proc_qor > $cur_flow_rpt_dir/06_proc_qor.rpt
report_qor > $cur_flow_rpt_dir/06_qor.rpt
report_power > $cur_flow_rpt_dir/06_power.rpt
#source -e -v /proj/7nm_evl/WORK/dong/7nm/xm_cpu/DCG/fp_05/check_7nm.tcl
#check_cell_area > $cur_flow_rpt_dir/06_vt_ratio.tcl
sh touch $cur_flow_rpt_dir/dcg_ready

write_icc2_files -force -output $cur_flow_data_dir/icc2_06

