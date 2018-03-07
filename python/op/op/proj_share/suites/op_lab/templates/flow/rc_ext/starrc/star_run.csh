#!/bin/csh -f
#################################
##link database to dst database##
#################################

#set pre_stage = icc2_route_opt
#set cur_stage = starrc
set pre_stage = "{{pre.sub_stage}}"
set cur_stage = "{{cur.sub_stage}}"

set pre_stage = `echo $pre_stage | cut -d . -f 1`
set cur_stage = `echo $cur_stage | cut -d . -f 1`

##mkdir tool output dirctory
set cur_flow_data_dir = "{{cur.flow_data_dir}}/{{cur.stage}}"
set pre_flow_data_dir = "{{pre.flow_data_dir}}/{{pre.stage}}"
set cur_flow_rpt_dir  = "{{cur.flow_rpt_dir}}/{{cur.stage}}"
set cur_flow_log_dir  = "{{cur.flow_log_dir}}/{{cur.stage}}"
set cur_flow_sum_dir  = "{{cur.flow_sum_dir}}/{{cur.stage}}"

 mkdir -p $cur_flow_data_dir
 mkdir -p $cur_flow_rpt_dir
 mkdir -p $cur_flow_log_dir
 mkdir -p $cur_flow_sum_dir

##link previous stage data
ln -sf $pre_flow_data_dir/$pre_stage.{{env.BLK_NAME}}.v $cur_flow_data_dir/$cur_stage.{{env.BLK_NAME}}.v.gz

echo "delete exsting smc files and starrc command file"
rm {{cur.flow_scripts_dir}}/{{cur.stage}}/*.smc
rm {{cur.flow_scripts_dir}}/{{cur.stage}}/*.cmd
 
#################################
## STAR flow                   ##
#################################
set tech_node                   = "{{local.tech_node}}"
set star_flow_type              = "{{local.star_flow_type}}"
set ndm_block_name              = "{{local.ndm_block_name}}"
set BLK_NAME                    = "{{env.BLK_NAME}}"
set STAR_MAPPING_FILE           = "{{liblist.STAR_MAPPING_FILE}}"
set star_cpu_number             = "{{local.star_cpu_number}}"
{%- if local.conds is string %} 
set CONDS                       = "{{local.conds}}" 
{%- elif local.conds is sequence %}
set CONDS                       = "{{local.conds|join(' ') }}" 
{%- endif %}
set dpt                         = "{{local.dpt}}"
set extract_via_caps            = "{{local.extract_via_caps}}"
set simultaneous_multi_corner   = "{{local.simultaneous_multi_corner}}"
{%- if local.selected_corners is string %}
set selected_corners            = "{{local.selected_corners}}"
{%- elif local.selected_corners is sequence %} 
set selected_corners            = "{{local.selected_corners|join(' ')}}"
{%- endif %}
set metal_fill_polygon_handling = "{{local.metal_fill_polygon_handling}}"
set GDS_LAYER_MAP_FILE          = "{{liblist.STAR_METAL_FILL_MAPPING_FILE}}"
set COUPLING_ABS_THRESHOLD      = "{{local.coupling_abs_threshold}}"
set COUPLING_REL_THRESHOLD      = "{{local.coupling_rel_threshold}}"

set NDM_TECH                    = "{{liblist.NDM_TECH}}"
set NDM_STD                     = "{{liblist.NDM_STD}}"
#$NDM_MEM      
#$NDM_IP     
#$NDM_IO

{%- if local.star_flow_type == "ndm" %} 
{%- if local.ndm_block_name ==  "" %}
set ndm_block_name           =  {{env.BLK_NAME}}/$pre_stage 
{%- else %}
set ndm_block_name           = $ndm_block_name
{%- endif %}
set BLOCK                    =	$ndm_block_name 
{%- elif local.star_flow_type == "deflef" %} 
set BLOCK                    =	 $BLK_NAME
{%- elif star_flow_type == "milkyway" %} 
set BLOCK                    =	 $BLK_NAME
{%- endif %}

set DEF                          = "$pre_flow_data_dir/${pre_stage}.{{env.BLK_NAME}}.def.gz"
#set LEFFILE                      =	"$LEF_TECH $LEF_STD      $LEF_MEM      $LEF_IP      $LEF_IO"
set MILKYWAY_DATABASE            =	"$pre_flow_data_dir/${pre_stage}.{{env.BLK_NAME}}.mw" 
set NDM_DATABASE                 = "$pre_flow_data_dir/${pre_stage}.{{env.BLK_NAME}}.nlib"
#set NDM_SEARCH_PATH             = "$NDM_TECH $NDM_STD      $NDM_MEM      $NDM_IP      $NDM_IO"
set NDM_SEARCH_PATH              = "$NDM_TECH $NDM_STD"

if ( -e `find $pre_flow_data_dir/* -name DVIA_${pre_stage}.${BLK_NAME}.gds.gz` ) then
set METAL_FILL_GDS_FILE          = `find {{pre.flow_data_dir}}/* -name DVIA_${pre_stage}.${BLK_NAME}.gds.gz` 
else
set METAL_FILL_GDS_FILE          = ""
endif

######################
# if CONDS or SELECTED_CORNERS are emptpy in config file, Warning... 
######################

{%- if local.conds == "" %} 
echo "Alchip-Warning: No CONDS is set"
{%- endif %}

{%- if local.selected_corners == "" %} 
echo "Alchip-Warning: No SELECTED_CORNERS are selected"
{%- endif %}

foreach COND ( $CONDS )
	 if (${COND} == "cworst") then
		set GRD =  "{{liblist.CWORST_NXTGRD_FILE}}"
	else if (${COND} == "cbest") then
		set GRD =  "{{liblist.CBEST_NXTGRD_FILE}}"
	else if (${COND} == "rcworst") then
		set GRD =  "{{liblist.RCWORST_NXTGRD_FILE}}"
	else if (${COND} == "rcbest") then
		set GRD =  "{{liblist.RCBEST_NXTGRD_FILE}}"
	else if (${COND} == "typical") then
		set GRD =  "{{liblist.TYPICAL_NXTGRD_FILE}}"
	else if (${COND} == "cworst_CCworst") then
		set GRD =  "{{liblist.CWORST_CCWORST_NXTGRD_FILE}}"
	else if (${COND} == "cworst_CCworst_T") then
		set GRD =  "{{liblist.CWORST_CCWORST_T_NXTGRD_FILE}}"
	else if (${COND} == "cbest_CCbest") then
		set GRD =  "{{liblist.CBEST_CCBEST_NXTGRD_FILE}}"
    else if (${COND} == "cbest_CCbest_T") then
		set GRD =  "{{liblist.CBEST_CCBEST_T_NXTGRD_FILE}}" 
    else if (${COND} == "rcworst_CCworst") then
		set GRD =  "{{liblist.RCWORST_CCWORST_NXTGRD_FILE}}"
	else if (${COND} == "rcworst_CCworst_T") then
		set GRD =  "{{liblist.RCWORST_CCWORST_T_NXTGRD_FILE}}" 
	else if (${COND} == "rcbest_CCbest") then
		set GRD =  "{{liblist.RCBEST_CCBEST_NXTGRD_FILE}}" 
	else if (${COND} == "rcbest_CCbest_T") then
		set GRD =  "{{liblist.RCBEST_CCBEST_T_NXTGRD_FILE}}" 
    else if (${COND} == "cbest_T") then
		set GRD =  "{{liblist.CBEST_T_NXTGRD_FILE}}" 
    else if (${COND} == "cworst_T") then
		set GRD =  "{{liblist.CWORST_T_NXTGRD_FILE}}" 
    else if (${COND} == "rcbest_T") then
		set GRD =  "{{liblist.RCBEST_T_NXTGRD_FILE}}" 
    else if (${COND} == "rcworst_T") then
		set GRD =  "{{liblist.RCWORST_T_NXTGRD_FILE}}"  
    endif

############generate smc file for each condition########
echo "generating smc file for $COND"

if ( ${COND} == "typical" ) then
   set tempratures = " 25c 85c"
else
   set tempratures = "125c m40c 0c"

endif

foreach tempr ( $tempratures )
 
 if ( $tempr == m40c ) then
 set atempr = "-40"
 else if ( $tempr == 125c ) then
 set atempr = 125
 else if ( $tempr == 0c ) then
 set atempr = 0
 else if ( $tempr == 25c ) then
 set atempr = 25
 else if ( $tempr == 85c ) then
 set atempr = 85
 endif

cat <<FP > {{cur.flow_scripts_dir}}/{{cur.stage}}/{{env.BLK_NAME}}.${COND}_${tempr}.smc

CORNER_NAME: ${COND}_$tempr
TCAD_GRD_FILE: $GRD
OPERATING_TEMPERATURE: $atempr

FP

end
end

cat {{cur.flow_scripts_dir}}/{{cur.stage}}/{{env.BLK_NAME}}.*.smc > {{cur.flow_scripts_dir}}/{{cur.stage}}/{{env.BLK_NAME}}.smc
rm {{cur.flow_scripts_dir}}/{{cur.stage}}/{{env.BLK_NAME}}*_*.smc

############generate cmd file for each condition########

echo "********** Starting {{local.conds}} ..."
set SESSION	   = ${cur_stage}{{env.BLK_NAME}}
set SPEF	   = $cur_flow_data_dir/${SESSION}.spef

echo "generating ${SESSION}.cmd file for {{local.conds}}"
########################################
#              flow                    #
########################################
cat << FP >! {{cur.flow_scripts_dir}}/{{cur.stage}}/${SESSION}.cmd
{% if local.star_flow_type == "deflef" %}
{% include 'starrc/star_deflef.cmd' %}
{% elif local.star_flow_type == "ndm" %}
{% include 'starrc/star_ndm.cmd' %}
{% elif local.star_flow_type == "milkyway" %}
{% include 'starrc/star_milkyway.cmd' %}
{% endif %}
FP
	
	############Print all the variables########
	echo "****************************************************"
	echo "Design Name                : {{env.BLK_NAME}}"
    echo STAR_MAPPING_FILE           : {{liblist.STAR_MAPPING_FILE}}
    echo star_cpu_number             : {{local.star_cpu_number}}
    echo conds                       : {{local.conds}}
    echo dpt                         : {{local.dpt}}
    echo extract_via_caps            : {{local.extract_via_caps}}
    echo simultaneous_multi_corner   : {{local.simultaneous_multi_corner}}
    echo selected_corners            : {{local.selected_corners}}
    echo metal_fill_polygon_handling : {{local.metal_fill_polygon_handling}}
    echo GDS_LAYER_MAP_FILE          : {{liblist.STAR_METAL_FILL_MAPPING_FILE}}
    echo COUPLING_ABS_THRESHOLD      : {{local.coupling_abs_threshold}}
    echo COUPLING_REL_THRESHOLD      : {{local.coupling_rel_threshold}}
	echo "****************************************************"
	############################################
    # Run STARRC                               #	
    ############################################ 

set star_mem_requirement = `expr {{local.star_mem_requirement}} / 10000`
echo $star_mem_requirement
absub -r "q:{{local.openlava_batch_queue}} os:6 M:$star_mem_requirement star:true n:$star_cpu_number" -c "StarXtract {{cur.flow_scripts_dir}}/{{cur.stage}}/${SESSION}.cmd"

    ############################################
    # change out put spef file naming          #	
    ############################################ 

    foreach selected_corner ($selected_corners)
    set i = 1
    set tmp =  `echo $selected_corner | awk '{print $i}'`
    if (-e $cur_flow_data_dir/${SESSION}.spef) then
    mv $cur_flow_data_dir/${SESSION}.spef $cur_flow_data_dir/${SESSION}.spef.$tmp
    endif

    if ( -e $cur_flow_data_dir/${SESSION}.spef.$tmp ) then
    gzip $cur_flow_data_dir/${SESSION}.spef.$tmp
    mv $cur_flow_data_dir/${SESSION}.spef.$tmp.gz $cur_flow_data_dir/{{env.BLK_NAME}}.$tmp.spef.gz
    endif
    end

############################################
# move report                              #	
############################################ 


if ( $star_flow_type == "deflef" || $star_flow_type == "mw") then
mv {{env.BLK_NAME}}.star_sum $cur_flow_log_dir/${cur_stage}.{{env.BLK_NAME}}.star_sum
endif

if ( $star_flow_type == "ndm") then

set block_name = `echo $ndm_block_name | cut -d / -f 1`
set label_name = `echo $ndm_block_name | cut -d / -f 2`

mv ${block_name}.star_sum $cur_flow_log_dir/${cur_stage}.{{env.BLK_NAME}}.star_sum
endif

mv  ./star/xtract.tech $cur_flow_log_dir/${cur_stage}.{{env.BLK_NAME}}.xtract.tech
mv ./star/tech_file.asc $cur_flow_log_dir/${cur_stage}.{{env.BLK_NAME}}.tech_file.asc

if (-e ./star/shorts_all.sum) then
mv ./star/shorts_all.sum $cur_flow_log_dir/${cur_stage}.{{env.BLK_NAME}}.shorts_all.sum
endif
if (-e ./star/opens.sum) then
mv ./star/opens.sum $cur_flow_log_dir/${cur_stage}.{{env.BLK_NAME}}.opens.sum
endif

#./scr/signoff_check/csh/check_starrc_log.csh $RUN_DIR $BLOCK_NAME $OP4_dst_eco

rm -rf ./star




