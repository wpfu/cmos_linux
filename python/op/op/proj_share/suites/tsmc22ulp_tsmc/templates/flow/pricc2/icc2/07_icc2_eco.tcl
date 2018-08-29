##########################################################################################
# Tool: IC Compiler II
##########################################################################################
puts "Alchip-info : Running script [info script]\n"
set sh_continue_on_error true

##===================================================================##
## SETUP                                                             ##
##===================================================================##
source {{env.PROJ_SHARE_CMN}}/icc2_common_scripts/icc2_procs.tcl
source {{env.PROJ_LIB}}/liblist/{{ver.LIB}}.tcl
source {{cur.cur_flow_sum_dir}}/{{cur.sub_stage}}.op._job.tcl
# include 00_icc2_setup.tcl
{% include 'icc2/00_icc2_setup.tcl' %}

set pre_stage "{{pre.sub_stage}}"
set cur_stage "{{cur.sub_stage}}"

set pre_stage [lindex [split $pre_stage .] 0]
set cur_stage [lindex [split $cur_stage .] 0]

set blk_name          "{{env.BLK_NAME}}"
set blk_rpt_dir       "{{cur.cur_flow_rpt_dir}}"
set blk_utils_dir     "{{env.PROJ_UTILS}}"
set blk_proj_cmn      "{{env.PROJ_SHARE_CMN}}"
set blk_plugins_dir   "{{cur.config_plugins_dir}}/icc2_scripts/07_eco"
set pre_flow_data_dir "{{pre.flow_data_dir}}/{{pre.stage}}"
set cur_design_library "{{cur.cur_flow_data_dir}}/$cur_stage.{{env.BLK_NAME}}.nlib"
set icc2_cpu_number   "[lindex "${_job_cpu_number}" end]"
set_host_option -max_cores $icc2_cpu_number

set pre_design_library  "$pre_flow_data_dir/$pre_stage.{{env.BLK_NAME}}.nlib"
set cur_design_library "{{cur.cur_flow_data_dir}}/$cur_stage.{{env.BLK_NAME}}.nlib"

set ocv_mode          "{{local.ocv_mode}}" 
set write_def_convert_icc2_site_to_lef_site_name_list "{{local.write_def_convert_icc2_site_to_lef_site_name_list}}"
set icc_icc2_gds_layer_mapping_file                     "{{liblist.ICC_ICC2_GDS_LAYER_MAPPING_FILE}}"
{%- if local.tcl_placement_spacing_label_rule_file %}
set TCL_PLACEMENT_SPACING_LABEL_RULE_FILE "{{local.tcl_placement_spacing_label_rule_file}}"
{%- else %}
set TCL_PLACEMENT_SPACING_LABEL_RULE_FILE "{{env.PROJ_SHARE_CMN}}/icc2_common_scripts/placement_spacing_rule.tcl"
{%- endif %}
{%- if local.tcl_icc2_cts_ndr_rule_file %}
set TCL_ICC2_CTS_NDR_RULE_FILE  "{{local.tcl_icc2_cts_ndr_rule_file}}"
{%- else %}
set TCL_ICC2_CTS_NDR_RULE_FILE  "{{env.PROJ_SHARE_CMN}}/icc2_common_scripts/icc2_cts_ndr_rule.tcl"
{%- endif %}

# ICC2 AOCV table----------------------------------------------------------------------
{%- if local.scenario_list is string %}
{%- set sn = local.scenario_list.upper().split('.') %}
{%- set sn_new = ['ICC2_AOCV', sn[1], sn[2], sn[4]]|join('_') %}
set ICC2_AOCV_{{sn[1]}}_{{sn[2]}}_{{sn[4]}}  "{{liblist[sn_new]}}"
{%- elif local.scenario_list is sequence %}
{%- for scenario in local.scenario_list %}
{%- set sn = scenario.upper().split('.') %}
{%- set sn_new = ['ICC2_AOCV', sn[1], sn[2], sn[4]]|join('_') %}
set ICC2_AOCV_{{sn[1]}}_{{sn[2]}}_{{sn[4]}}  "{{liblist[sn_new]}}"
{%- endfor %}
{%- endif %}
set ndm_tech          "{{liblist.NDM_TECH}}" 

##===================================================================##
## back up database                                                  ##
## copy block and lib from previous stage                            ## 
##===================================================================##
set bak_date [exec date +%m%d]
if {[file exist ${cur_design_library}] } {
if {[file exist ${cur_design_library}_bak_${bak_date}] } {
exec rm -rf ${cur_design_library}_bak_${bak_date}
}
exec mv -f ${cur_design_library} ${cur_design_library}_bak_${bak_date}
}
## copy block and lib from previous stage-------------------------------
copy_lib -from_lib ${pre_design_library} -to_lib ${cur_design_library} -no_design
open_lib ${pre_design_library}
copy_block -from ${pre_design_library}:{{env.BLK_NAME}}/${pre_stage} -to ${cur_design_library}:{{env.BLK_NAME}}/${cur_stage}
close_lib ${pre_design_library}
open_lib ${cur_design_library}
current_block {{env.BLK_NAME}}/${cur_stage}

link_block
save_lib

###==================================================================##
## source eco cart from plugin directory                             ##
## change eco cart name or add more eco file if necessary.           ##
##===================================================================##
{% if enable_manual_eco == "true" %} 
puts "Alchip-info: manual eco is enabled, please start manual work and save block before exit icc2!"
return 
{% else %}
source  -e -v  $blk_plugins_dir/eco_0.tcl
source  -e -v  $blk_plugins_dir/eco_1.tcl
source  -e -v  $blk_plugins_dir/eco_2.tcl
source  -e -v  $blk_plugins_dir/eco_3.tcl
{% endif %}
###==================================================================##
## save design                                                       ##
##===================================================================##
save_lib
