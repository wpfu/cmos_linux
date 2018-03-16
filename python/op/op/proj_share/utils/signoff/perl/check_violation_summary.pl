#!/usr/bin/perl

  ##################################################################################
  ## PROGRAM:     check_violation_summary.pl
  ## CREATOR:     Mitsuya Takashima <mitsuya@alchip.com>
  ## DATE:        Fri Sep 29 13:27:50 CST 2017
  ## DESCRIPTION: Check PT STA violations
  ## USAGE:       check_violation_summary.pl setup/hold.rep > setup/hold.rep.summary
  ## INFORMATION: default timing groups
  ##################################################################################

$check_block = 1 ;
$check_path_group = 0 ;
$check_clock_group = 1 ;
$check_stage_count = 1 ;
$check_clock_network_delay = 1 ;
$min_clock_paths_derating_factor = 1.0 ;
$max_clock_paths_derating_factor = 1.0 ;
#$resolution = "medium" ;
$resolution = "high" ;

$filter_block_internal = 0 ;
$detail_mcu_group = 0 ;

$design = "PS02" ; # force to set PS02

while( <> ) {
  split ;

  ########################################################################
  # check header
  #
  if( /^\**\s*Report  *: [tT]iming/ ) {
    $is_report_timing = 1 ;
  }
  if( /^Report : constraint/ ) {
    $is_report_timing = 1 ;
  }
  if( /-path full_clock/ ) {
    $check_clock_network_delay = 0 ;
  }
  if( ( /-delay min/ ) || ( /-delay_type min/ ) || ( /Path Type: min/ ) ) {
    $resolution = "high" ;
  }
  if( /-nets/ ) {
    $check_stage_count = 1 ;
  }
  if( /^\**\s*Design\s*:\s*(\S+)/ ) {
    ( $design ) = /^\**\s*Design\s*:\s*(\S+)/ ;
  }
  if( /^# Mantle analysis report\s*$/ ) {
    $is_report_timing = 1 ;
    $check_stage_count = 0 ;
    $check_clock_network_delay = 1 ;
    $check_path_group = 0 ;
  }

  ########################################################################
  # check header
  #
  if( /^\**\s*(Path|Delay) Type: (min|max)/ ) {
    ( $dummy, $path_type ) = /^\**\s*(Path|Delay) Type: (min|max)/ ;
    if( $path_type eq "min" ) {
     #$resolution = "high" ;
    }
  }
# if( /Derating Factor/ ) {
#   $is_timing_derate = 1 ;
# }
# if( /^\**\s*Min Clock Paths Derating Factor : (\S+)/ ) {
#   ( $min_clock_paths_derating_factor ) = /^\**\s*Min Clock Paths Derating Factor : (\S+)/ ;
# }
# if( /^\**\s*Max Clock Paths Derating Factor : (\S+)/ ) {
#   ( $max_clock_paths_derating_factor ) = /^\**\s*Max Clock Paths Derating Factor : (\S+)/ ;
# }

  ########################################################################
  # get startpoint (instance)
  #
  if( /^\**\s*(Start|Begin)point:\s+(\S+)/ ) {
    ( $dummy, $startpoint_pin ) = /^\s*(Start|Begin)point:\s+(\S+)/ ;
    $startpoint_clock = "" ;
    $startpoint_clock_root_arrival = "" ;
    $startpoint_derating_clock_network_delay = "" ;
    $endpoint_pin = "" ;
    $endpoint_clock = "" ;
    $endpoint_clock_root_arrival = "" ;
    $endpoint_derating_clock_network_delay = "" ;

    $is_data_path = 0 ;
    $stage_count = 0 ;

    $startpoint_pattern = $startpoint_pin ;
    $startpoint_pattern =~ s/([\[\]])/\\$1/g ;

#   $delay_cell_found = 0 ;

    $crp = 0.000 ;
  }

  ########################################################################
  # get path group
  #
  if( $check_path_group == 1 ) {
    if( /^\**\s*Path Group:\s+(\S+)/ ) {
      ( $path_group ) = /^\s*Path Group:\s+(\S+)/ ;
      $path_group =~ s/^.*\/// if( $design eq "Tachyon2HDD" || $design eq "Tachyon2S" ) ; # Tachyon2HDD
    }
  }

  ########################################################################
  # get clock
  #
  if( /\(.* clocked by (\S+)\)/ ) {
    ( $clock ) = /\(.* clocked by (\S+)\)/ ;
    if( $startpoint_clock eq "" ) {
      $startpoint_clock = $clock ;
      $startpoint = "$startpoint_pin:$startpoint_clock" ;
     #$startpoint_clock_root_arrival = 0 ;
     #$clock_root_arrival{$startpoint} = $startpoint_clock_root_arrival ;
    } elsif( $endpoint_clock eq "" ) {
      $endpoint_clock = $clock ;
      $endpoint = "$endpoint_pin:$endpoint_clock" ;
     #$endpoint_clock_root_arrival = 0 ;
     #$clock_root_arrival{$endpoint} = $endpoint_clock_root_arrival ;

      if( $check_clock_group == 1 ) {
        $clock_group = "$startpoint_clock,$endpoint_clock" ;
        if( $worst_slack_per_clock_group{$clock_group} eq "" ) {
            $worst_slack_per_clock_group{$clock_group} = 999999 ;
        }
      }
    }
  }
  if( /\((recovery|removal) check against (rising|falling)-edge clock (\S+)\)/ ) {
    ( $check, $edge, $clock ) = /\((recovery|removal) check against (rising|falling)-edge clock (\S+)\)/ ;
    if( $startpoint_clock eq "" ) {
      $startpoint_clock = $clock ;
      $startpoint = "$startpoint_pin:$startpoint_clock" ;
     #$startpoint_clock_root_arrival = 0 ;
     #$clock_root_arrival{$startpoint} = $startpoint_clock_root_arrival ;
    } elsif( $endpoint_clock eq "" ) {
      $endpoint_clock = $clock ;
      $endpoint = "$endpoint_pin:$endpoint_clock" ;
     #$endpoint_clock_root_arrival = 0 ;
     #$clock_root_arrival{$endpoint} = $endpoint_clock_root_arrival ;

      if( $check_clock_group == 1 ) {
        $clock_group = "$startpoint_clock,$endpoint_clock" ;
        if( $worst_slack_per_clock_group{$clock_group} eq "" ) {
            $worst_slack_per_clock_group{$clock_group} = 999999 ;
        }
      }
    }
  }
  if( /\(clock source '(\S+)'\)/ ) {
    ( $clock ) = /\(clock source '(\S+)'\)/ ;
    if( $startpoint_clock eq "" ) {
      $startpoint_clock = $clock ;
      $startpoint = "$startpoint_pin:$startpoint_clock" ;
     #$startpoint_clock_root_arrival = 0 ;
     #$clock_root_arrival{$startpoint} = $startpoint_clock_root_arrival ;
    } elsif( $endpoint_clock eq "" ) {
      $endpoint_clock = $clock ;
      $endpoint = "$endpoint_pin:$endpoint_clock" ;
     #$endpoint_clock_root_arrival = 0 ;
     #$clock_root_arrival{$endpoint} = $endpoint_clock_root_arrival ;
    
      if( $check_clock_group == 1 ) {
        $clock_group = "$startpoint_clock,$endpoint_clock" ;
        if( $worst_slack_per_clock_group{$clock_group} eq "" ) {
            $worst_slack_per_clock_group{$clock_group} = 999999 ;
        } 
      }
    }
  }
  if( /^\s*clock (\S+) \((\S+ edge|re|fe)\)\s+(\d*\.*\d+)\s+/ ) {
    if( ( $startpoint_clock eq "" ) && ( $endpoint_clock eq "" ) ) {
      ( $startpoint_clock, $dummy, $startpoint_clock_root_arrival ) = /^\s*clock (\S+) \((\S+ edge|re|fe)\)\s+(\d*\.*\d+)\s+/ ;
      $startpoint_clock =~ s/^.*\/// if( $design eq "Tachyon2HDD" || $design eq "Tachyon2S" ) ; # Tachyon2HDD
      $startpoint = "$startpoint_pin:$startpoint_clock" ;
    } elsif( ( $startpoint_clock ne "" ) && ( $endpoint_clock eq "" ) ) {
      ( $endpoint_clock, $dummy, $endpoint_clock_root_arrival ) = /^\s*clock (\S+) \((\S+ edge|re|fe)\)\s+(\d*\.*\d+)\s+/ ;
      $endpoint_clock =~ s/^.*\/// if( $design eq "Tachyon2HDD" || $design eq "Tachyon2S" ) ; # Tachyon2HDD
      $endpoint = "$endpoint_pin:$endpoint_clock" ;
      $clock_root_arrival{$endpoint} = $endpoint_clock_root_arrival ;

      if( $check_clock_group == 1 ) {
        $clock_group = "$startpoint_clock,$endpoint_clock" ;
        if( $worst_slack_per_clock_group{$clock_group} eq "" ) {
            $worst_slack_per_clock_group{$clock_group} = 999999 ;
        }
      }
    }
  }

  ########################################################################
  # get clock network delay
  #
  if( /^\**\s*clock (network|tree) delay \(propagated|ideal\)\s+(\S+)\s+/ ) {
    if( $startpoint_derating_clock_network_delay eq "" ) {
#     ( $startpoint_derating_clock_network_delay ) = /^\**\s*clock (network|tree) delay \(propagated|ideal\)\s+(\S+)\s+/ ;
      $startpoint_derating_clock_network_delay = $_[4] ;
    } elsif( $endpoint_derating_clock_network_delay eq "" ) {
#     ( $endpoint_derating_clock_network_delay ) = /^\**\s*clock (network|tree) delay \(propagated|ideal\)\s+(\S+)\s+/ ;
      $endpoint_derating_clock_network_delay = $_[4] ;
    }
  }

  ########################################################################
  # check pin for startpoint and endpoint
  #
  if( /^\**\s*(\S+) \((\S+)\)\s+(\S+)\s+(\S+)/ ) {
    $is_pin = 1 ;
    $is_pin = 0 if( /\(net\)/ ) ;
    ( $pin, $cell ) =
     /^\**\s*(\S+)\s+\((\S+)\)\s+(\S+)\s+(\S+)/ if( $is_pin == 1 ) ;
  }
  if( /^\**\s*(\S+) \((\S+)\)$/ ) {
    $is_pin = 1 ;
    $is_pin = 0 if( /\(net\)/ ) ;
    ( $pin, $cell ) =
     /^\**\s*(\S+)\s+\((\S+)\)$/ if( $is_pin == 1 ) ;
  }

  ########################################################################
  # check delay for stage count (exclude hierarchical pin)
  #
  if( /\s+(\d*\.*\d+)\s+(\*|&)*\s*(\d*\.*\d+)\s+(r|f|R|F)\s*/ ) {
    unless( /\(net\)/ ) {
      ( $delay ) =
      /\s+(\d*\.*\d+)\s+(\*|&)*\s*(\d*\.*\d+)\s+(r|f|R|F)\s*/ ;
    }
  }

  ########################################################################
  # get startpoint (pin)
  #
  if( $is_data_path == 0 ) {
    if( ( $pin eq $startpoint_pin ) || ( $pin =~ /^($startpoint_pattern)\// ) ) {
      $startpoint_pin = $pin ;
      $startpoint = "$startpoint_pin:$startpoint_clock" ;
      $clock_root_arrival{$startpoint} = $startpoint_clock_root_arrival ;

      $is_data_path = 1 ;

      ##### ONLY FOR T2 #####
      if( $design eq "Tachyon2HDD" || $design eq "Tachyon2S" ) {
        $startpoint_block = $startpoint_pin ;
        if( $startpoint_pin !~ /\// ) {
          $startpoint_block = "in" ;
        } else {
          $startpoint_block =~ s/^d29[0-9][0-9]\/top\/sc_/d2986\/top\/sc\// ;
          $startpoint_block =~ s/^d29[0-9][0-9]\/top\/me_/d2986\/top\/me\// ;
          $startpoint_block =~ s/^d29[0-9][0-9]\/top\/pb_/d2986\/top\/pb\// ;
          $startpoint_block =~ s/^d29[0-9][0-9]\/top\/ck_/d2986\/top\/ck\// ;
          if( $startpoint_block =~ /^d29[0-9][0-9]\/top\/me\/mcpu\// ) { $startpoint_block = "d2986/top/me/mcpu (CPU_MEDIA)" }
          elsif( $startpoint_block =~ /^d29[0-9][0-9]\/top\/me\/mvme\// ) { $startpoint_block = "d2986/top/me/mvme (VETOP)" }
          elsif( $startpoint_block =~ /^d29[0-9][0-9]\/top\/me\/mavc\// ) { $startpoint_block = "d2986/top/me/mavc (A1RING)" }
          elsif( $startpoint_block =~ /^d29[0-9][0-9]\/top\/me\/mahbm\// ) { $startpoint_block = "d2986/top/me/mahbm/*" }
          elsif( $startpoint_block =~ /^d29[0-9][0-9]\/top\/me\/mahbs\// ) { $startpoint_block = "d2986/top/me/mahbs/*" }
          elsif( $startpoint_block =~ /^d29[0-9][0-9]\/top\/me\/mdmac\// ) { $startpoint_block = "d2986/top/me/mdmac/*" }
          elsif( $startpoint_block =~ /^d29[0-9][0-9]\/top\/me\/mvld\// ) { $startpoint_block = "d2986/top/me/mvld/*" }
          elsif( $startpoint_block =~ /^d29[0-9][0-9]\/top\/me\// ) { $startpoint_block = "d2986/top/me/*" }

          elsif( $startpoint_block =~ /^d29[0-9][0-9]\/top\/sc\/scpu\// ) { $startpoint_block = "d2986/top/sc/scpu (CPU_MAIN)" }
          elsif( $startpoint_block =~ /^d29[0-9][0-9]\/top\/sc\/scpu_wrap\/scpu\// ) { $startpoint_block = "d2986/top/sc/scpu_wrap/scpu (CPU_MAIN_WRAP)" }
          elsif( $startpoint_block =~ /^d29[0-9][0-9]\/top\/sc\/saw_a\// ) { $startpoint_block = "d2986/top/sc/saw_a (aw_a)" }
          elsif( $startpoint_block =~ /^d29[0-9][0-9]\/top\/sc\/semc1\/emc_io_wrapper\// ) { $startpoint_block = "d2986/top/sc/semc1/emc_io_wrapper (EMC_DDR_IO_WRAPPER_R2P0)" }
          elsif( $startpoint_block =~ /^d29[0-9][0-9]\/top\/sc\/skirk\// ) { $startpoint_block = "d2986/top/sc/skirk/*" }
          elsif( $startpoint_block =~ /^d29[0-9][0-9]\/top\/sc\/sata\// ) { $startpoint_block = "d2986/top/sc/sata/*" }
          elsif( $startpoint_block =~ /^d29[0-9][0-9]\/top\/sc\/satahdd\// ) { $startpoint_block = "d2986/top/sc/satahdd/*" }
          elsif( $startpoint_block =~ /^d29[0-9][0-9]\/top\/sc\/smrom\// ) { $startpoint_block = "d2986/top/sc/smrom/*" }
          elsif( $startpoint_block =~ /^d29[0-9][0-9]\/top\/sc\/sahbm\// ) { $startpoint_block = "d2986/top/sc/sahbm/*" }
          elsif( $startpoint_block =~ /^d29[0-9][0-9]\/top\/sc\/sahbs\// ) { $startpoint_block = "d2986/top/sc/sahbs/*" }
          elsif( $startpoint_block =~ /^d29[0-9][0-9]\/top\/sc\/sdmac0\// ) { $startpoint_block = "d2986/top/sc/sdmac0/*" }
          elsif( $startpoint_block =~ /^d29[0-9][0-9]\/top\/sc\/sdmac1\// ) { $startpoint_block = "d2986/top/sc/sdmac1/*" }
          elsif( $startpoint_block =~ /^d29[0-9][0-9]\/top\/sc\/sdmac2\// ) { $startpoint_block = "d2986/top/sc/sdmac2/*" }
          elsif( $startpoint_block =~ /^d29[0-9][0-9]\/top\/sc\/sms1\// ) { $startpoint_block = "d2986/top/sc/sms1/*" }
          elsif( $startpoint_block =~ /^d29[0-9][0-9]\/top\/sc\/sms2\// ) { $startpoint_block = "d2986/top/sc/sms2/*" }
          elsif( $startpoint_block =~ /^d29[0-9][0-9]\/top\/sc\/spmem\// ) { $startpoint_block = "d2986/top/sc/spmem/*" }
          elsif( $startpoint_block =~ /^d29[0-9][0-9]\/top\/sc\/sshr\// ) { $startpoint_block = "d2986/top/sc/sshr/*" }
          elsif( $startpoint_block =~ /^d29[0-9][0-9]\/top\/sc\/susb\// ) { $startpoint_block = "d2986/top/sc/susb/*" }
          elsif( $startpoint_block =~ /^d29[0-9][0-9]\/top\/sc\// ) { $startpoint_block = "d2986/top/sc/*" }

          elsif( $startpoint_block =~ /^d29[0-9][0-9]\/top\/pb\/pspi2\// ) { $startpoint_block = "d2986/top/me/pspi2/*" }
          elsif( $startpoint_block =~ /^d29[0-9][0-9]\/top\/pb\/pmib\// ) { $startpoint_block = "d2986/top/pb/pmib/*" }
          elsif( $startpoint_block =~ /^d29[0-9][0-9]\/top\/pb\// ) { $startpoint_block = "d2986/top/pb/*" }

          elsif( $startpoint_block =~ /^d29[0-9][0-9]\/top\/ck\// ) { $startpoint_block = "d2986/top/ck/*" }
          elsif( $startpoint_block =~ /^d29[0-9][0-9]\/top\/pll\// ) { $startpoint_block = "d2986/top/pll/*" }
          elsif( $startpoint_block =~ /^d29[0-9][0-9]\/top\/dbtest\// ) { $startpoint_block = "d2986/top/dbtest/*" }
          elsif( $startpoint_block =~ /^d29[0-9][0-9]\/top\/fuse\// ) { $startpoint_block = "d2986/top/fuse/*" }
          elsif( $startpoint_block =~ /^d29[0-9][0-9]\/top\/BPM[^\/]+\// ) { $startpoint_block = "d2986/top/BPM*" }
          elsif( $startpoint_block =~ /^d29[0-9][0-9]\/top\// ) { $startpoint_block = "d2986/top/*" }
          elsif( $startpoint_block =~ /^d29[0-9][0-9]\/[^\/]+_SF_reg\// ) { $startpoint_block = "d2986/*_SF_reg" }
          elsif( $startpoint_block =~ /^d29[0-9][0-9]\// ) { $startpoint_block = "d2986/*" }
          elsif( $startpoint_block =~ /^Venus\// ) { $startpoint_block = "Venus/*" }
          elsif( $startpoint_block =~ /^mercury\// ) { $startpoint_block = "mercury" }
          else { $startpoint_block = "*" }
        }
      ##### ONLY FOR DJIN #####
      } elsif( $design eq "DJINIO" ) {
        if( $startpoint_pin !~ /\// ) {
          $startpoint_block = "in" ;
        } elsif( $startpoint_pin =~ /\/SC900DRM[^\/]+\/[^\/]+$/i ) {
          $startpoint_block = "DRAM" ;
        } elsif( $startpoint_pin =~ /\/LV[12]P[^\/]+\/[^\/]+$/ ) {
          $startpoint_block = "SRAM" ;
        } elsif( $startpoint_pin =~ /FUSEBOX/ ) {
          $startpoint_block = "FUSEBOX" ;
        } elsif( $startpoint_pin =~ /_collar\/[^\/]+_FLOP_reg/ ) {
          $startpoint_block = "MBIST" ;
        } elsif( $startpoint_pin =~ /\/[^\/]+reg[^\/]*\/[^\/]+$/ ) {
          $startpoint_block = "DFF" ;
        } elsif( $startpoint_pin eq "djin_0/dadc_0/sc900xapaa00_0/CLKPcheckpin1" ) {
          $startpoint_block = "ADC" ;
        } else {
          $startpoint_block = "?" ;
        }
      ##### ONLY FOR HYDRA2IO #####
      } elsif( $design eq "HYDRA2IO" ) {
        if( $startpoint_pin !~ /\// ) {
          $startpoint_block = "in" ;
       #} elsif( $startpoint_pin =~ /^hydra2_0\/kcore_0\// ) {
       #  $startpoint_block = "KCORE" ;
       #} elsif( $startpoint_pin =~ /^hydra2_0\/dcore_0\/dcofdm1_0\// ) {
       #  $startpoint_block = "DCOFDM1" ;
        } elsif( $startpoint_pin =~ /^TACOTAPC/ ) {
          $startpoint_block = "*TAPC*" ;
        } elsif( $startpoint_pin =~ /^[A-Z0-9]+_0_[A-Z0-9]+\/(SF|UP)_reg\// ) {
          $startpoint_block = "*BSC*" ;
        } elsif( $startpoint_pin =~ /^([^\/]+\/[^\/]+)\/\S+/ ) {
          $startpoint_block = $startpoint_pin ;
          $startpoint_block =~ s/^([^\/]+\/[^\/]+)\/\S+$/\1\/\*/ ;
        } else {
          $startpoint_block = "*TOP*" ;
        }
      ##### ONLY FOR MCTEG0 #####
      } elsif( $design eq "MCTEG0" ) {
        if(      $startpoint_pin !~ /\// ) {
                 $startpoint_block = "in" ;
        } elsif( $startpoint_pin =~ /^topl\/DDRCONE\/emc\/EMC_DDR_IO_WRAPPER_R2P0\/emc_ddr_io\// ) {
                 $startpoint_block = "emc_ddr_io\/*" ;
        } else {
                 $startpoint_block = $startpoint_pin ;
                #$startpoint_block =~ s/\/.*$// ;
                #$startpoint_block =~ s/^([^\/]+)\/\S+$/\1\/\*/ ;
                 $startpoint_block =~ s/^([^\/]+\/[^\/]+)\/\S+$/\1\/\*/ ;
        }
      ##### ONLY FOR SDCHIP #####
      } elsif( $design eq "top" ) {
        if( $startpoint_pin !~ /\// ) {
                 $startpoint_block = "in" ;
        } elsif( $startpoint_pin =~ /^ahb2apb_/ ) {
                 $startpoint_block = "ahb2apb_*" ;
        } elsif( $startpoint_pin =~ /^(ahb_[^_\/]+_).*$/ ) {
                 $startpoint_block = $startpoint_pin ;
                 $startpoint_block =~ s/^(ahb_[^_\/]+_).*$/\1_\*/ ;
        } elsif( $startpoint_pin =~ /^(apb_[^_\/]+_).*$/ ) {
                 $startpoint_block = $startpoint_pin ;
                 $startpoint_block =~ s/^(apb_[^_\/]+_).*$/\1_\*/ ;
        } elsif( $startpoint_pin =~ /^([^\/]+)\/\S+/ ) {
                 $startpoint_block = $startpoint_pin ;
                 $startpoint_block =~ s/^([^\/]+)\/\S+$/\1\/\*/ ;
        } else {
                 $startpoint_block = "*TOP*" ;
        }
      ##### ONLY FOR RODEO6 #####
      } elsif( $design eq "rodeo6" ) {
        if( $startpoint_pin !~ /\// ) {
                 $startpoint_block = "in" ;
        } elsif( $startpoint_pin   =~  /^(rodeo6_top)\/(backend|top_mcu|gcg)\/([^\/]+)\/(\S+)$/ ) {
                 $startpoint_block = $startpoint_pin ;
                 $startpoint_block =~ s/^(rodeo6_top)\/(backend|top_mcu|gcg)\/([^\/]+)\/(\S+)$/\2\/\3\/\*/ ;
        } elsif( $startpoint_pin   =~  /^(rodeo6_top)\/([^\/]+)\/(\S+)$/ ) {
                 $startpoint_block = $startpoint_pin ;
                 $startpoint_block =~ s/^(rodeo6_top)\/([^\/]+)\/(\S+)$/\2\/\*/ ;
        } else {
                 $startpoint_block = "*TOP*" ;
        }
      ##### ONLY FOR T2CD #####
      } elsif( $design eq "d2993" ) {
        $startpoint_block = $startpoint_pin ;
        if( $startpoint_pin !~ /\// ) { $startpoint_block = "in" }
        elsif( $startpoint_pin   =~  /^top\/me\/mavc\// ) { $startpoint_block = "top/me/mavc (A1RING)" }
        elsif( $startpoint_pin   =~  /^top\/me\/mvme\// ) { $startpoint_block = "top/me/mvme (VETOP)" }
        elsif( $startpoint_pin   =~  /^top\/me\/mcpu\// ) { $startpoint_block = "top/me/mcpu (CPU_MEDIA)" }
        elsif( $startpoint_pin   =~  /^top\/sc\/scpu\// ) { $startpoint_block = "top/sc/scpu (CPU_MAIN)" }
        elsif( $startpoint_pin   =~  /^top\/sc\/saw_a\// ) { $startpoint_block = "top/sc/saw_a (aw_)" }
        elsif( $startpoint_pin   =~  /^top\/sc\/semc1\/emc_io_wrapper\// ) { $startpoint_block = "top/sc/semc1/emc_io_wrapper (EMC_DDR_IO_WRAPPER_R2P0)" }
        elsif( $startpoint_pin   =~  /^top\/ck\// ) { $startpoint_block = "top/ck (ck)" }
        elsif( $startpoint_pin   =~  /^[^\/]+_[A-Z]+\/[A-Z]+_reg\// ) { $startpoint_block = "*BSC*" }
        else { $startpoint_block = "*TOP*" }
      } elsif( $design eq "t2cd" ) {
        $startpoint_block = $startpoint_pin ;
        if( $startpoint_pin !~ /\// ) { $startpoint_block = "in" }
        elsif( $startpoint_pin   =~  /^d2993\/top\/me\/mavc\// ) { $startpoint_block = "d2993/top/me/mavc (A1RING)" }
        elsif( $startpoint_pin   =~  /^d2993\/top\/me\/mvme\// ) { $startpoint_block = "d2993/top/me/mvme (VETOP)" }
        elsif( $startpoint_pin   =~  /^d2993\/top\/me\/mcpu\// ) { $startpoint_block = "d2993/top/me/mcpu (CPU_MEDIA)" }
        elsif( $startpoint_pin   =~  /^d2993\/top\/sc\/scpu\// ) { $startpoint_block = "d2993/top/sc/scpu (CPU_MAIN)" }
        elsif( $startpoint_pin   =~  /^d2993\/top\/sc\/saw_a\// ) { $startpoint_block = "d2993/top/sc/saw_a (aw_)" }
        elsif( $startpoint_pin   =~  /^d2993\/top\/sc\/semc1\/emc_io_wrapper\// ) { $startpoint_block = "d2993/top/sc/semc1/emc_io_wrapper (EMC_DDR_IO_WRAPPER_R2P0)" }
        elsif( $startpoint_pin   =~  /^d2993\/top\/ck\// ) { $startpoint_block = "d2993/top/ck (ck)" }
        elsif( $startpoint_pin   =~  /^d2993\/[^\/]+_[A-Z]+\/[A-Z]+_reg\// ) { $startpoint_block = "*BSC*" }
        elsif( $startpoint_pin   =~  /^cdram\// ) { $startpoint_block = "cdram (cdram)" }
        else { $startpoint_block = "*TOP*" }
      } elsif( $design eq "HYDRA5IO" ) {
        $startpoint_block = $startpoint_pin ;
        if( $startpoint_pin !~ /\// ) { $startpoint_block = "in" }
        elsif( $startpoint_block =~ /^hydra5_0\/(\w+_0\/\w+_0)\/\S+$/ ) { $startpoint_block =~ s/^hydra5_0\/(\w+_0\/\w+_0)\/\S+$/\1\/\*/ }
        elsif( $startpoint_block =~ /^hydra5_0\/(\w+_0)\/\S+$/ ) { $startpoint_block =~ s/^hydra5_0\/(\w+_0)\/\S+$/\1\/\*/ }
        else { $startpoint_block = "*TOP*" }
      } elsif( $design eq "D4191" ) {
        $startpoint_block = $startpoint_pin ;
        if( $startpoint_pin !~ /\// ) { $startpoint_block = "in" }
        elsif( $startpoint_block =~ /^(mbcon_[^\/]+)\/\S+$/ ) { $startpoint_block =~ s/^(mbcon_[^\/]+)\/\S+$/\1\/\*/ }
        elsif( $startpoint_block =~ /^(\w+\/\w+\/\w+)\/\S+$/ ) { $startpoint_block =~ s/^(\w+\/\w+\/\w+)\/\S+$/\1\/\*/ }
        elsif( $startpoint_block =~ /^(\w+\/\w+)\/\S+$/      ) { $startpoint_block =~ s/^(\w+\/\w+)\/\S+$/\1\/\*/ }
        elsif( $startpoint_block =~ /^(\w+)\/\S+$/           ) { $startpoint_block =~ s/^(\w+)\/\S+$/\1\/\*/ }
        else { $startpoint_block = "*TOP*" }

      # Ganesha
      } elsif( $design eq "ZUDM" ) {
        $startpoint_block = $startpoint_pin ;
        if( $startpoint_pin !~ /\// ) { $startpoint_block = "in" }
        elsif( $startpoint_block =~ /TMC_YV3_DEC_BASE_TOP_02/ ) { $startpoint_block = "TMC_YV3_DEC_BASE_TOP_02" }
        elsif( $startpoint_block =~ /TMC_YV3_DEC_BASE_TOP_13/ ) { $startpoint_block = "TMC_YV3_DEC_BASE_TOP_13" }
        else { $startpoint_block = "ZUDM" }

      } elsif( $design eq "ZTOP" ) {
        $startpoint_block = $startpoint_pin ;
        if( $startpoint_pin !~ /\// ) { $startpoint_block = "in" }
        elsif( $startpoint_block =~ /\/SCSPHY0123\/C0/ ) { $startpoint_block = "SCSPHY0123(0)" }
        elsif( $startpoint_block =~ /\/SCSPHY0123\/C1/ ) { $startpoint_block = "SCSPHY0123(1)" }
        elsif( $startpoint_block =~ /\/SCSPHY0123\/C2/ ) { $startpoint_block = "SCSPHY0123(2)" }
        elsif( $startpoint_block =~ /\/SCSPHY0123\/C3/ ) { $startpoint_block = "SCSPHY0123(3)" }
        elsif( $startpoint_block =~ /\/SCSPHY4567\/C0/ ) { $startpoint_block = "SCSPHY4567(0)" }
        elsif( $startpoint_block =~ /\/SCSPHY4567\/C1/ ) { $startpoint_block = "SCSPHY4567(1)" }
        elsif( $startpoint_block =~ /\/SCSPHY4567\/C2/ ) { $startpoint_block = "SCSPHY4567(2)" }
        elsif( $startpoint_block =~ /\/SCSPHY4567\/C3/ ) { $startpoint_block = "SCSPHY4567(3)" }
        else { $startpoint_block = "*TOP*" }

      } elsif( $design eq "PS02" ) {
        $startpoint_block = $startpoint_pin ;
        if( $startpoint_pin !~ /\// ) {
          $startpoint_block = "in" ;
        } else {
          $startpoint_block = $startpoint_pin ;

          $startpoint_block =~ s/(BISTCON_FBOX)_\S+/${1}_\*/ ;
          $startpoint_block =~ s/(ALCHIP_DFTC_LOGIC)\S+/${1}\*/ ;
          $startpoint_block =~ s/(ALCHIP_sean_fix)_\S+/${1}\*/ ;
          $startpoint_block =~ s/(LOCKUP)\S+/${1}\*/ ;
          $startpoint_block =~ s/(RETIMING_FLOP)\S+/${1}\*/ ;
          $startpoint_block =~ s/(SCAN_dummy_reg_post)_\S+/${1}_\*/ ;
          $startpoint_block =~ s/(SCAN_dummy_reg_pre)_\S+/${1}_\*/ ;
          $startpoint_block =~ s/(SNPS_PipeHead)_\S+/${1}_\*/ ;
          $startpoint_block =~ s/(SNPS_PipeTail)_\S+/${1}_\*/ ;
          $startpoint_block =~ s/(udtp)_\S+/${1}_\*/ ;
          $startpoint_block =~ s/(dft_reg)_\S+/${1}_\*/ ;

          $startpoint_block =~ s/^(DCIO_\d+\/p\d+\/phy)\/\S+/${1}/ ;
          $startpoint_block =~ s/^(DCIO_\d+\/c\d+a_wrap\/c\d+)\/\S+/${1}/ ;
          $startpoint_block =~ s/^(STU\/ETH)\/\S+$/${1}/ ;
          $startpoint_block =~ s/^(STU\/MEMIO)\/\S+$/${1}/ ;
          $startpoint_block =~ s/^(STU\/SD0TOP)\/\S+$/${1}/ ;
          $startpoint_block =~ s/^(STU\/SD1TOP)\/\S+$/${1}/ ;
          $startpoint_block =~ s/^(STU\/SD2TOP)\/\S+$/${1}/ ;
          $startpoint_block =~ s/^(ISRX\/LINK_TOP)\/\S+$/${1}/ ;

          $startpoint_block =~ s/^(MCU\/NoC_Top\/i_Mem_Int_Arc_St\/m_PD01)\/\S+$/MCU\(Mem_Int:1\)/ ;
          $startpoint_block =~ s/^(MCU\/NoC_Top\/i_Mem_Int_Arc_St\/m_PD06)\/\S+$/MCU\(Mem_Int:2\)/ ;
          $startpoint_block =~ s/^(MCU\/NoC_Top\/i_Mem_Int_Arc_St\/m_PD30)\/\S+$/MCU\(Mem_Int:3\)/ ;
          $startpoint_block =~ s/^(MCU\/NoC_Top\/i_Mem_Int_Arc_St\/m_PD_DEF01_600\/NIUs_To_Scheduler)\/\S+$/MCU\(Mem_Int:4\)/ ;
          $startpoint_block =~ s/^(MCU\/NoC_Top\/i_S_MainNoC_Arc_St\/m_PD_A10)\/\S+$/MCU\(MainNoC:NIU\)/ ;
          $startpoint_block =~ s/^(MCU\/NoC_Top\/i_S_MainNoC_Arc_St\/m_PD_A35)\/\S+$/MCU\(MainNoC:NIU\)/ ;
          $startpoint_block =~ s/^(MCU\/NoC_Top\/i_S_MainNoC_Arc_St\/m_PD_A36)\/\S+$/MCU\(MainNoC:NIU\)/ ;
          $startpoint_block =~ s/^(MCU\/NoC_Top\/i_S_MainNoC_Arc_St\/m_PD_A39)\/\S+$/MCU\(MainNoC:NIU\)/ ;
          $startpoint_block =~ s/^(MCU\/NoC_Top\/i_S_MainNoC_Arc_St\/m_PD_B12)\/\S+$/MCU\(MainNoC:NIU\)/ ;
          $startpoint_block =~ s/^(MCU\/NoC_Top\/i_S_MainNoC_Arc_St\/m_PD_B13)\/\S+$/MCU\(MainNoC:NIU\)/ ;
          $startpoint_block =~ s/^(MCU\/NoC_Top\/i_S_MainNoC_Arc_St\/m_PD_C17)\/\S+$/MCU\(MainNoC:NIU\)/ ;
          $startpoint_block =~ s/^(MCU\/NoC_Top\/i_S_MainNoC_Arc_St\/m_PD_C18)\/\S+$/MCU\(MainNoC:NIU\)/ ;
          $startpoint_block =~ s/^(MCU\/NoC_Top\/i_S_MainNoC_Arc_St\/m_PD_C19)\/\S+$/MCU\(MainNoC:NIU\)/ ;
          $startpoint_block =~ s/^(MCU\/NoC_Top\/i_S_MainNoC_Arc_St\/m_PD_D14)\/\S+$/MCU\(MainNoC:NIU\)/ ;
          $startpoint_block =~ s/^(MCU\/NoC_Top\/i_S_MainNoC_Arc_St\/m_PD_D15)\/\S+$/MCU\(MainNoC:NIU\)/ ;
          $startpoint_block =~ s/^(MCU\/NoC_Top\/i_S_MainNoC_Arc_St\/m_PD_D16)\/\S+$/MCU\(MainNoC:NIU\)/ ;
          $startpoint_block =~ s/^(MCU\/NoC_Top\/i_S_MainNoC_Arc_St\/m_PD_DEF00\/NIUs_ODU0)\/\S+$/MCU\(MainNoC:NIU\)/ ;
          $startpoint_block =~ s/^(MCU\/NoC_Top\/i_S_MainNoC_Arc_St\/m_PD_DEF00\/NIUs_PCIe_reg)\/\S+$/MCU\(MainNoC:NIU\)/ ;
          $startpoint_block =~ s/^(MCU\/NoC_Top\/i_S_MainNoC_Arc_St\/m_PD_DEF01\/NIUs_To_ReorderBuffer\/NIU_to_DRAM_0)\/\S+$/MCU\(MainNoC:NIU\)/ ;
          $startpoint_block =~ s/^(MCU\/NoC_Top\/i_S_MainNoC_Arc_St\/m_PD_DEF01\/NIUs_To_ReorderBuffer\/NIU_to_DRAM_1)\/\S+$/MCU\(MainNoC:NIU\)/ ;
          $startpoint_block =~ s/^(MCU\/NoC_Top\/i_S_MainNoC_Arc_St\/m_PD_DEF01\/NIUs_To_ReorderBuffer\/NIU_to_DRAM_4)\/\S+$/MCU\(MainNoC:NIU\)/ ;
          $startpoint_block =~ s/^(MCU\/NoC_Top\/i_S_MainNoC_Arc_St\/m_PD_DEF01\/NIUs_To_ReorderBuffer\/NIU_to_DRAM_5)\/\S+$/MCU\(MainNoC:NIU\)/ ;
          $startpoint_block =~ s/^(MCU\/NoC_Top\/i_S_MainNoC_Arc_St\/m_PD_DEF01\/NIUs_To_ReorderBuffer\/NIU_to_DRAM_6)\/\S+$/MCU\(MainNoC:NIU\)/ ;
          $startpoint_block =~ s/^(MCU\/NoC_Top\/i_S_MainNoC_Arc_St\/m_PD_DEF02\/NIUs_GEVG)\/\S+$/MCU\(MainNoC:NIU\)/ ;
          $startpoint_block =~ s/^(MCU\/NoC_Top\/i_S_MainNoC_Arc_St\/m_PD_DEF06\/NIUs_ADU)\/\S+$/MCU\(MainNoC:NIU\)/ ;
          $startpoint_block =~ s/^(MCU\/NoC_Top\/i_S_MainNoC_Arc_St\/m_PD_DEF06\/NIUs_JPU)\/\S+$/MCU\(MainNoC:NIU\)/ ;
          $startpoint_block =~ s/^(MCU\/NoC_Top\/i_S_MainNoC_Arc_St\/m_PD_DEF06\/NIUs_STU_ETH)\/\S+$/MCU\(MainNoC:NIU\)/ ;
          $startpoint_block =~ s/^(MCU\/NoC_Top\/i_S_MainNoC_Arc_St\/m_PD_DEF06\/NIUs_STU_SD2)\/\S+$/MCU\(MainNoC:NIU\)/ ;
          $startpoint_block =~ s/^(MCU\/NoC_Top\/i_S_MainNoC_Arc_St\/m_PD_DEF07\/NIUs_STU_SD0)\/\S+$/MCU\(MainNoC:NIU\)/ ;
          $startpoint_block =~ s/^(MCU\/NoC_Top\/i_S_MainNoC_Arc_St\/m_PD_DEF07\/NIUs_STU_SD1)\/\S+$/MCU\(MainNoC:NIU\)/ ;
          $startpoint_block =~ s/^(MCU\/NoC_Top\/i_S_MainNoC_Arc_St\/m_PD_DEF07\/NIUs_STU_other_mas)\/\S+$/MCU\(MainNoC:NIU\)/ ;
          $startpoint_block =~ s/^(MCU\/NoC_Top\/i_S_MainNoC_Arc_St\/m_PD_DEF07\/NIUs_STU_other_slv)\/\S+$/MCU\(MainNoC:NIU\)/ ;
          $startpoint_block =~ s/^(MCU\/NoC_Top\/i_S_MainNoC_Arc_St\/m_PD_DEF08\/NIUs_MIU_mas)\/\S+$/MCU\(MainNoC:NIU\)/ ;
          $startpoint_block =~ s/^(MCU\/NoC_Top\/i_S_MainNoC_Arc_St\/m_PD_DEF08\/NIUs_MIU_slv)\/\S+$/MCU\(MainNoC:NIU\)/ ;
          $startpoint_block =~ s/^(MCU\/NoC_Top\/i_S_MainNoC_Arc_St\/m_PD_DEF08\/NIUs_VOU_monm_pro)\/\S+$/MCU\(MainNoC:NIU\)/ ;
          $startpoint_block =~ s/^(MCU\/NoC_Top\/i_S_MainNoC_Arc_St\/m_PD_DEF08\/NIUs_VOU_mont)\/\S+$/MCU\(MainNoC:NIU\)/ ;
          $startpoint_block =~ s/^(MCU\/NoC_Top\/i_S_MainNoC_Arc_St\/m_PD_DEF08\/NIUs_VOU_other_mas)\/\S+$/MCU\(MainNoC:NIU\)/ ;
          $startpoint_block =~ s/^(MCU\/NoC_Top\/i_S_MainNoC_Arc_St\/m_PD_DEF08\/NIUs_VOU_other_slv)\/\S+$/MCU\(MainNoC:NIU\)/ ;
          $startpoint_block =~ s/^(MCU\/NoC_Top\/i_S_MainNoC_Arc_St\/m_PD_DEF08\/NIUs_VOU_sub_mont)\/\S+$/MCU\(MainNoC:NIU\)/ ;
          $startpoint_block =~ s/^(MCU\/NoC_Top\/i_S_MainNoC_Arc_St\/m_PD_DEF09\/NIUs_TCC)\/\S+$/MCU\(MainNoC:NIU\)/ ;
          $startpoint_block =~ s/^(MCU\/NoC_Top\/i_S_MainNoC_Arc_St\/m_PD_F21)\/\S+$/MCU\(MainNoC:NIU\)/ ;
          $startpoint_block =~ s/^(MCU\/NoC_Top\/i_S_MainNoC_Arc_St\/m_PD_F22)\/\S+$/MCU\(MainNoC:NIU\)/ ;
          $startpoint_block =~ s/^(MCU\/NoC_Top\/i_S_MainNoC_Arc_St\/m_PD_F23_0)\/\S+$/MCU\(MainNoC:NIU\)/ ;
          $startpoint_block =~ s/^(MCU\/NoC_Top\/i_S_MainNoC_Arc_St\/m_PD_F23_1)\/\S+$/MCU\(MainNoC:NIU\)/ ;
          $startpoint_block =~ s/^(MCU\/NoC_Top\/i_S_MainNoC_Arc_St\/m_PD_F24_f32)\/\S+$/MCU\(MainNoC:NIU\)/ ;
          $startpoint_block =~ s/^(MCU\/NoC_Top\/i_S_MainNoC_Arc_St\/m_PD_F24_f4)\/\S+$/MCU\(MainNoC:NIU\)/ ;
          $startpoint_block =~ s/^(MCU\/NoC_Top\/i_S_MainNoC_Arc_St\/m_PD_F24_uec)\/\S+$/MCU\(MainNoC:NIU\)/ ;
          $startpoint_block =~ s/^(MCU\/NoC_Top\/i_S_MainNoC_Arc_St\/m_PD_F24_ume)\/\S+$/MCU\(MainNoC:NIU\)/ ;
          $startpoint_block =~ s/^(MCU\/NoC_Top\/i_S_MainNoC_Arc_St\/m_PD_F24_usc)\/\S+$/MCU\(MainNoC:NIU\)/ ;
          $startpoint_block =~ s/^(MCU\/NoC_Top\/i_S_MainNoC_Arc_St\/m_PD_H20)\/\S+$/MCU\(MainNoC:NIU\)/ ;
          $startpoint_block =~ s/^(MCU\/NoC_Top\/i_S_MainNoC_Arc_St\/m_PD_J07)\/\S+$/MCU\(MainNoC:NIU\)/ ;
          $startpoint_block =~ s/^(MCU\/NoC_Top\/i_S_MainNoC_Arc_St\/m_PD_L33)\/\S+$/MCU\(MainNoC:NIU\)/ ;
          $startpoint_block =~ s/^(MCU\/NoC_Top\/i_S_MainNoC_Arc_St\/m_PD_L34)\/\S+$/MCU\(MainNoC:NIU\)/ ;
          $startpoint_block =~ s/^(MCU\/NoC_Top\/i_S_MainNoC_Arc_St\/m_PD_U08_0)\/\S+$/MCU\(MainNoC:NIU\)/ ;
          $startpoint_block =~ s/^(MCU\/NoC_Top\/i_S_MainNoC_Arc_St\/m_PD_V28)\/\S+$/MCU\(MainNoC:NIU\)/ ;
          $startpoint_block =~ s/^(MCU\/NoC_Top\/i_S_MainNoC_Arc_St\/m_PD_V29)\/\S+$/MCU\(MainNoC:NIU\)/ ;
          $startpoint_block =~ s/^(MCU\/NoC_Top\/i_S_PeriNoC_Arc_St\/m_PD_B12)\/\S+$/MCU\(PeriNoC:NIU\)/ ;
          $startpoint_block =~ s/^(MCU\/NoC_Top\/i_S_PeriNoC_Arc_St\/m_PD_B13)\/\S+$/MCU\(PeriNoC:NIU\)/ ;
          $startpoint_block =~ s/^(MCU\/NoC_Top\/i_S_PeriNoC_Arc_St\/m_PD_C14)\/\S+$/MCU\(PeriNoC:NIU\)/ ;
          $startpoint_block =~ s/^(MCU\/NoC_Top\/i_S_PeriNoC_Arc_St\/m_PD_C15)\/\S+$/MCU\(PeriNoC:NIU\)/ ;
          $startpoint_block =~ s/^(MCU\/NoC_Top\/i_S_PeriNoC_Arc_St\/m_PD_C16)\/\S+$/MCU\(PeriNoC:NIU\)/ ;
          $startpoint_block =~ s/^(MCU\/NoC_Top\/i_S_PeriNoC_Arc_St\/m_PD_C17)\/\S+$/MCU\(PeriNoC:NIU\)/ ;
          $startpoint_block =~ s/^(MCU\/NoC_Top\/i_S_PeriNoC_Arc_St\/m_PD_C19)\/\S+$/MCU\(PeriNoC:NIU\)/ ;
          $startpoint_block =~ s/^(MCU\/NoC_Top\/i_S_PeriNoC_Arc_St\/m_PD_DEF00\/NIU_ISRX)\/\S+$/MCU\(PeriNoC:NIU\)/ ;
          $startpoint_block =~ s/^(MCU\/NoC_Top\/i_S_PeriNoC_Arc_St\/m_PD_DEF00\/NIUs_ODU0)\/\S+$/MCU\(PeriNoC:NIU\)/ ;
          $startpoint_block =~ s/^(MCU\/NoC_Top\/i_S_PeriNoC_Arc_St\/m_PD_DEF00\/NIUs_PCIe_reg)\/\S+$/MCU\(PeriNoC:NIU\)/ ;
          $startpoint_block =~ s/^(MCU\/NoC_Top\/i_S_PeriNoC_Arc_St\/m_PD_DEF01\/NIUs_DCIO_0)\/\S+$/MCU\(PeriNoC:NIU\)/ ;
          $startpoint_block =~ s/^(MCU\/NoC_Top\/i_S_PeriNoC_Arc_St\/m_PD_DEF02\/NIUs_GEVG)\/\S+$/MCU\(PeriNoC:NIU\)/ ;
          $startpoint_block =~ s/^(MCU\/NoC_Top\/i_S_PeriNoC_Arc_St\/m_PD_DEF03\/NIUs_MCU)\/\S+$/MCU\(PeriNoC:NIU\)/ ;
          $startpoint_block =~ s/^(MCU\/NoC_Top\/i_S_PeriNoC_Arc_St\/m_PD_DEF05\/NIUs_PCIe_reg)\/\S+$/MCU\(PeriNoC:NIU\)/ ;
          $startpoint_block =~ s/^(MCU\/NoC_Top\/i_S_PeriNoC_Arc_St\/m_PD_DEF06\/NIUs_ADU)\/\S+$/MCU\(PeriNoC:NIU\)/ ;
          $startpoint_block =~ s/^(MCU\/NoC_Top\/i_S_PeriNoC_Arc_St\/m_PD_DEF06\/NIUs_DITX)\/\S+$/MCU\(PeriNoC:NIU\)/ ;
          $startpoint_block =~ s/^(MCU\/NoC_Top\/i_S_PeriNoC_Arc_St\/m_PD_DEF06\/NIUs_JPU)\/\S+$/MCU\(PeriNoC:NIU\)/ ;
          $startpoint_block =~ s/^(MCU\/NoC_Top\/i_S_PeriNoC_Arc_St\/m_PD_DEF06\/NIUs_LCU)\/\S+$/MCU\(PeriNoC:NIU\)/ ;
          $startpoint_block =~ s/^(MCU\/NoC_Top\/i_S_PeriNoC_Arc_St\/m_PD_DEF06\/NIUs_STU_ETH)\/\S+$/MCU\(PeriNoC:NIU\)/ ;
          $startpoint_block =~ s/^(MCU\/NoC_Top\/i_S_PeriNoC_Arc_St\/m_PD_DEF06\/NIUs_STU_SD2)\/\S+$/MCU\(PeriNoC:NIU\)/ ;
          $startpoint_block =~ s/^(MCU\/NoC_Top\/i_S_PeriNoC_Arc_St\/m_PD_DEF07\/NIUs_HDMI)\/\S+$/MCU\(PeriNoC:NIU\)/ ;
          $startpoint_block =~ s/^(MCU\/NoC_Top\/i_S_PeriNoC_Arc_St\/m_PD_DEF07\/NIUs_STU_SD0)\/\S+$/MCU\(PeriNoC:NIU\)/ ;
          $startpoint_block =~ s/^(MCU\/NoC_Top\/i_S_PeriNoC_Arc_St\/m_PD_DEF07\/NIUs_STU_SD1)\/\S+$/MCU\(PeriNoC:NIU\)/ ;
          $startpoint_block =~ s/^(MCU\/NoC_Top\/i_S_PeriNoC_Arc_St\/m_PD_DEF07\/NIUs_STU_other_slv)\/\S+$/MCU\(PeriNoC:NIU\)/ ;
          $startpoint_block =~ s/^(MCU\/NoC_Top\/i_S_PeriNoC_Arc_St\/m_PD_DEF08\/NIUs_MIU_slv)\/\S+$/MCU\(PeriNoC:NIU\)/ ;
          $startpoint_block =~ s/^(MCU\/NoC_Top\/i_S_PeriNoC_Arc_St\/m_PD_DEF08\/NIUs_MIU_slv_APB_I4)\/\S+$/MCU\(PeriNoC:NIU\)/ ;
          $startpoint_block =~ s/^(MCU\/NoC_Top\/i_S_PeriNoC_Arc_St\/m_PD_DEF08\/NIUs_MIU_slv_APB_I9)\/\S+$/MCU\(PeriNoC:NIU\)/ ;
          $startpoint_block =~ s/^(MCU\/NoC_Top\/i_S_PeriNoC_Arc_St\/m_PD_DEF08\/NIUs_PMU)\/\S+$/MCU\(PeriNoC:NIU\)/ ;
          $startpoint_block =~ s/^(MCU\/NoC_Top\/i_S_PeriNoC_Arc_St\/m_PD_DEF08\/NIUs_SSG)\/\S+$/MCU\(PeriNoC:NIU\)/ ;
          $startpoint_block =~ s/^(MCU\/NoC_Top\/i_S_PeriNoC_Arc_St\/m_PD_DEF09\/NIUs_TCC)\/\S+$/MCU\(PeriNoC:NIU\)/ ;
          $startpoint_block =~ s/^(MCU\/NoC_Top\/i_S_PeriNoC_Arc_St\/m_PD_DEF11\/NIUs_CKG)\/\S+$/MCU\(PeriNoC:NIU\)/ ;
          $startpoint_block =~ s/^(MCU\/NoC_Top\/i_S_PeriNoC_Arc_St\/m_PD_H20)\/\S+$/MCU\(PeriNoC:NIU\)/ ;
          $startpoint_block =~ s/^(MCU\/NoC_Top\/i_S_PeriNoC_Arc_St\/m_PD_J07)\/\S+$/MCU\(PeriNoC:NIU\)/ ;
          $startpoint_block =~ s/^(MCU\/NoC_Top\/i_S_PeriNoC_Arc_St\/m_PD_L33)\/\S+$/MCU\(PeriNoC:NIU\)/ ;
          $startpoint_block =~ s/^(MCU\/NoC_Top\/i_S_PeriNoC_Arc_St\/m_PD_L34)\/\S+$/MCU\(PeriNoC:NIU\)/ ;
          $startpoint_block =~ s/^(MCU\/NoC_Top\/i_S_PeriNoC_Arc_St\/m_PD_T01)\/\S+$/MCU\(PeriNoC:NIU\)/ ;
          $startpoint_block =~ s/^(MCU\/NoC_Top\/i_S_PeriNoC_Arc_St\/m_PD_T06)\/\S+$/MCU\(PeriNoC:NIU\)/ ;
          $startpoint_block =~ s/^(MCU\/NoC_Top\/i_S_PeriNoC_Arc_St\/m_PD_T30)\/\S+$/MCU\(PeriNoC:NIU\)/ ;
          $startpoint_block =~ s/^(MCU\/NoC_Top\/i_S_PeriNoC_Arc_St\/m_PD_U08_0)\/\S+$/MCU\(PeriNoC:NIU\)/ ;
          $startpoint_block =~ s/^(MCU\/NoC_Top\/i_S_PeriNoC_Arc_St\/m_PD_V28)\/\S+$/MCU\(PeriNoC:NIU\)/ ;
          $startpoint_block =~ s/^(MCU\/NoC_Top\/i_S_PeriNoC_Arc_St\/m_PD_V29)\/\S+$/MCU\(PeriNoC:NIU\)/ ;

          if( $detail_mcu_group == 1 ) {
          $startpoint_block =~   s/^(MCU\/NoC_Top\/i_Mem_Int_Arc_St)\/m_PD_(DEF\d+)\S+$/MCU\(Mem_Int:4\)/ ;
          $startpoint_block =~ s/^(MCU\/NoC_Top\/i_S_MainNoC_Arc_St)\/m_PD_(DEF\d+)\S+$/MCU\(MainNoC:\2\)/ ;
          $startpoint_block =~ s/^(MCU\/NoC_Top\/i_S_PeriNoC_Arc_St)\/m_PD_(DEF\d+)\S+$/MCU\(PeriNoC:\2\)/ ;
          $startpoint_block =~ s/^(MCU\/NoC_Top\/i_S_MainNoC_Arc_St)\/\S+$/MCU\(MainNoC\)/ ;
          $startpoint_block =~ s/^(MCU\/NoC_Top\/i_S_PeriNoC_Arc_St)\/\S+$/MCU\(PeriNoC\)/ ;
          }

          $startpoint_block =~ s/\/.*$// if( $startpoint_block eq $startpoint_pin ) ;
        }
      } elsif( $design eq "VP1" ) {
        $startpoint_block = $startpoint_pin ;
        if( $startpoint_pin !~ /\// ) {
          $startpoint_block = "in" ;
        } else {
          $startpoint_block = $startpoint_pin ;

         #$startpoint_block =~ s/(BISTCON_FBOX)_\S+/${1}_\*/ ;
         #$startpoint_block =~ s/(ALCHIP_DFTC_LOGIC)\S+/${1}\*/ ;
         #$startpoint_block =~ s/(ALCHIP_sean_fix)_\S+/${1}\*/ ;
         #$startpoint_block =~ s/(LOCKUP)\S+/${1}\*/ ;
         #$startpoint_block =~ s/(RETIMING_FLOP)\S+/${1}\*/ ;
         #$startpoint_block =~ s/(SCAN_dummy_reg_post)_\S+/${1}_\*/ ;
         #$startpoint_block =~ s/(SCAN_dummy_reg_pre)_\S+/${1}_\*/ ;
         #$startpoint_block =~ s/(SNPS_PipeHead)_\S+/${1}_\*/ ;
         #$startpoint_block =~ s/(SNPS_PipeTail)_\S+/${1}_\*/ ;
         #$startpoint_block =~ s/(udtp)_\S+/${1}_\*/ ;
         #$startpoint_block =~ s/(dft_reg)_\S+/${1}_\*/ ;

          $startpoint_block =~ s/^(CORE\/CPUPERI\/HTOP\/HBUSTOP)\/\S+/${1}/ ;
          $startpoint_block =~ s/^(CORE\/CPUPERI\/HCPU)\/\S+/${1}/ ;
          $startpoint_block =~ s/^(CORE\/CPUPERI\/USB20TOP\/USB20_OLS\/USB20_ILS)\/\S+/${1}/ ;
          $startpoint_block =~ s/^(CORE\/CPUPERI\/USB30TOP\/USB30_OLS\/USB30_ILS)\/\S+/${1}/ ;
          $startpoint_block =~ s/^(CORE\/MBUSTOP\/MBUSTOP_CORE\/DDRB\/DDRB[01]\/U_DDR_PHY)\/\S+/${1}/ ;
          $startpoint_block =~ s/^(CORE\/MBUSTOP\/MBUSTOP_CORE)\/\S+/${1}/ if( $startpoint_block !~ /^(CORE\/MBUSTOP\/MBUSTOP_CORE\/DDRB\/DDRB[012]\/U_DDR_PHY)/ ) ;
          $startpoint_block =~ s/^(CORE\/VPU\/VBE_TOP\/vbe[012]\/pl)\/\S+/${1}/ ;
          $startpoint_block =~ s/^(CORE\/VPU\/VBE_TOP)\/\S+/${1}/ if( $startpoint_block !~ /^(CORE\/VPU\/VBE_TOP\/vbe[012]\/pl)/ ) ;
          $startpoint_block =~ s/^(CORE\/VPU\/RPP)\/\S+/${1}/ ;
          $startpoint_block =~ s/^(CORE\/VPU\/SPP\/SPP0\/S[ABC]ISP\/MIPIRX[01]_TOP\/CSI2M2S2_OLS\/CSI2M2S2_ILS)\/\S+/${1}/ ;
          $startpoint_block =~ s/^(CORE\/VPU\/SPP\/SPP1\/S[DEF]ISP\/MIPIRX[01]_TOP\/CSI2M2S2_OLS\/CSI2M2S2_ILS)\/\S+/${1}/ ;
          $startpoint_block =~ s/^(CORE\/VPU\/SPP\/SPP0)\/\S+/${1}/ if( $startponit_block !~ /^(CORE\/VPU\/SPP\/SPP0\/S[ABC]ISP\/MIPIRX[01]_TOP\/CSI2M2S2_OLS\/CSI2M2S2_ILS)/ ) ;
          $startpoint_block =~ s/^(CORE\/VPU\/SPP\/SPP1)\/\S+/${1}/ if( $startponit_block !~ /^(CORE\/VPU\/SPP\/SPP0\/S[DEF]ISP\/MIPIRX[01]_TOP\/CSI2M2S2_OLS\/CSI2M2S2_ILS)/ ) ;

          $startpoint_block =~ s/\/.*$// if( $startpoint_block eq $startpoint_pin ) ;
        }
      } elsif( $design eq "VBE_PL" ) {
        $startpoint_block = $startpoint_pin ;
        if( $startpoint_pin !~ /\// ) {
          $startpoint_block = "in" ;
        } else {
          $startpoint_block = $startpoint_pin ;

          $startpoint_block =~ s/^(pd\/cd\/[^\/]+)\/\S+/${1}\/\*/                   if( $startpoint_block !~ /^(pd\/cd\/core)\// ) ;
          $startpoint_block =~ s/^(pd\/cd\/core\/[^\/]+)\/\S+/${1}\/\*/             if( $startpoint_block !~ /^(pd\/cd\/core\/vp6)\// ) ;
          $startpoint_block =~ s/^(pd\/cd\/core\/vp6\/[^\/]+)\/\S+/${1}\/\*/        if( $startpoint_block !~ /^(pd\/cd\/core\/vp6\/xtmem)\// ) ;
          $startpoint_block =~ s/^(pd\/cd\/core\/vp6\/xtmem)\/\S+/${1}\/\*/         if( $startpoint_block !~ /^(pd\/cd\/core\/vp6\/xtmem)\/(Xttop|dram0|dram1|icache|iram0|itag)\// ) ;
          $startpoint_block =~ s/^(pd\/cd\/core\/vp6\/xtmem\/[^\/]+)\/\S+/${1}\/\*/ if( $startpoint_block =~ /^(pd\/cd\/core\/vp6\/xtmem)\/(Xttop|dram0|dram1|icache|iram0|itag)\// ) ;

          $startpoint_block =~ s/\/.*$// if( $startpoint_block eq $startpoint_pin ) ;
        }
      } elsif( $design eq "HCPU" ) {
        $startpoint_block = $startpoint_pin ;
        if( $startpoint_pin !~ /\// ) {
          $startpoint_block = "in" ;
        } else {
          $startpoint_block = $startpoint_pin ;

          $startpoint_block =~ s/^a9mp_top\/u_a9mp_pwrwrp_OLS\/u_a9mp_pwrwrp_ILS\/u_a9mp_wholewrp\/u_a9mp_testwrp\/u_a9mp_corewrp\/(u_CORTEXA9INTEGRATION\/u_falcon\/u_cpu0)\/\S+/...\/${1}\/\*/ if( $startpoint_block !~ /\/\*/ ) ;
          $startpoint_block =~ s/^a9mp_top\/u_a9mp_pwrwrp_OLS\/u_a9mp_pwrwrp_ILS\/u_a9mp_wholewrp\/u_a9mp_testwrp\/u_a9mp_corewrp\/(u_CORTEXA9INTEGRATION\/u_falcon\/u_cpu1)\/\S+/...\/${1}\/\*/ if( $startpoint_block !~ /\/\*/ ) ;
          $startpoint_block =~ s/^a9mp_top\/u_a9mp_pwrwrp_OLS\/u_a9mp_pwrwrp_ILS\/u_a9mp_wholewrp\/u_a9mp_testwrp\/u_a9mp_corewrp\/(u_CORTEXA9INTEGRATION\/u_falcon\/u_cpu2)\/\S+/...\/${1}\/\*/ if( $startpoint_block !~ /\/\*/ ) ;
          $startpoint_block =~ s/^a9mp_top\/u_a9mp_pwrwrp_OLS\/u_a9mp_pwrwrp_ILS\/u_a9mp_wholewrp\/u_a9mp_testwrp\/u_a9mp_corewrp\/(u_CORTEXA9INTEGRATION\/u_falcon\/u_cpu3)\/\S+/...\/${1}\/\*/ if( $startpoint_block !~ /\/\*/ ) ;
          $startpoint_block =~ s/^a9mp_top\/u_a9mp_pwrwrp_OLS\/u_a9mp_pwrwrp_ILS\/u_a9mp_wholewrp\/u_a9mp_testwrp\/u_a9mp_corewrp\/(u_CORTEXA9INTEGRATION\/u_falcon\/u_scu)\/\S+/...\/${1}\/\*/ if( $startpoint_block !~ /\/\*/ ) ;
          $startpoint_block =~ s/^a9mp_top\/u_a9mp_pwrwrp_OLS\/u_a9mp_pwrwrp_ILS\/u_a9mp_wholewrp\/u_a9mp_testwrp\/u_a9mp_corewrp\/(u_CORTEXA9INTEGRATION\/u_falcon\/u_clk_module)\/\S+/...\/${1}\/\*/ if( $startpoint_block !~ /\/\*/ ) ;
          $startpoint_block =~ s/^a9mp_top\/u_a9mp_pwrwrp_OLS\/u_a9mp_pwrwrp_ILS\/u_a9mp_wholewrp\/u_a9mp_testwrp\/u_a9mp_corewrp\/(u_CORTEXA9INTEGRATION\/u_falcon\/u_topmbmux)\/\S+/...\/${1}\/\*/ if( $startpoint_block !~ /\/\*/ ) ;
          $startpoint_block =~ s/^a9mp_top\/u_a9mp_pwrwrp_OLS\/u_a9mp_pwrwrp_ILS\/u_a9mp_wholewrp\/u_a9mp_testwrp\/u_a9mp_corewrp\/(u_CORTEXA9INTEGRATION\/u_falcon)\/\S+/...\/${1}\/\*/ if( $startpoint_block !~ /\/\*/ ) ;
          $startpoint_block =~ s/^a9mp_top\/u_a9mp_pwrwrp_OLS\/u_a9mp_pwrwrp_ILS\/u_a9mp_wholewrp\/u_a9mp_testwrp\/u_a9mp_corewrp\/([^\/]+)\/\S+/...\/${1}\/\*/ if( $startpoint_block !~ /\/\*/ ) ;
          $startpoint_block =~ s/^a9mp_top\/u_a9mp_pwrwrp_OLS\/u_a9mp_pwrwrp_ILS\/u_a9mp_wholewrp\/u_a9mp_testwrp\/([^\/]+)\/\S+/...\/${1}\/\*/ if( $startpoint_block !~ /\/\*/ ) ;
          $startpoint_block =~ s/^a9mp_top\/u_a9mp_pwrwrp_OLS\/u_a9mp_pwrwrp_ILS\/u_a9mp_wholewrp\/([^\/]+)\/\S+/...\/${1}\/\*/ if( $startpoint_block !~ /\/\*/ ) ;
          $startpoint_block =~ s/^a9mp_top\/u_a9mp_pwrwrp_OLS\/u_a9mp_pwrwrp_ILS\/([^\/]+)\/\S+/...\/${1}\/\*/ if( $startpoint_block !~ /\/\*/ ) ;
          $startpoint_block =~ s/^a9mp_top\/u_a9mp_pwrwrp_OLS\/([^\/]+)\/\S+/...\/${1}\/\*/ if( $startpoint_block !~ /\/\*/ ) ;
          $startpoint_block =~ s/^(a9mp_top\/[^\/]+)\/\S+/${1}\/\*/ if( $startpoint_block !~ /\/\*/ ) ;
          $startpoint_block =~ s/^([^\/]+)\/\S+/${1}\/\*/ if( $startpoint_block !~ /\/\*/ ) ;

         #$startpoint_block =~ s/\/.*$// if( $startpoint_block eq $startpoint_pin ) ;
        }
      ##### DEFAULT #####
      } else {
        if( $startpoint_pin !~ /\// ) {
          $startpoint_block = "in" ;
        } else {
          $startpoint_block = $startpoint_pin ;
          $startpoint_block =~ s/\/.*$// ;
        }
      }
    }
  }

  ########################################################################
  # get endpoint (pin)
  #
  if( ( /^\**\s*data arrival time / ) && ( $endpoint_pin eq "" ) ) {
    $endpoint_pin = $pin if( $pin ne "" ) ;
    $endpoint = "$endpoint_pin:$endpoint_clock" ;

    ##### ONLY FOR T2 #####
    if( $design eq "Tachyon2HDD" || $design eq "Tachyon2S" ) {
      $endpoint_block = $endpoint_pin ;
      if( $endpoint_pin !~ /\// ) {
        $endpoint_block = "out" ;
      } else {
        $endpoint_block =~ s/^d29[0-9][0-9]\/top\/sc_/d2986\/top\/sc\// ;
        $endpoint_block =~ s/^d29[0-9][0-9]\/top\/me_/d2986\/top\/me\// ;
        $endpoint_block =~ s/^d29[0-9][0-9]\/top\/pb_/d2986\/top\/pb\// ;
        $endpoint_block =~ s/^d29[0-9][0-9]\/top\/ck_/d2986\/top\/ck\// ;
        if( $endpoint_block =~ /^d29[0-9][0-9]\/top\/me\/mcpu\// ) { $endpoint_block = "d2986/top/me/mcpu (CPU_MEDIA)" }
        elsif( $endpoint_block =~ /^d29[0-9][0-9]\/top\/me\/mvme\// ) { $endpoint_block = "d2986/top/me/mvme (VETOP)" }
        elsif( $endpoint_block =~ /^d29[0-9][0-9]\/top\/me\/mavc\// ) { $endpoint_block = "d2986/top/me/mavc (A1RING)" }
        elsif( $endpoint_block =~ /^d29[0-9][0-9]\/top\/me\/mahbm\// ) { $endpoint_block = "d2986/top/me/mahbm/*" }
        elsif( $endpoint_block =~ /^d29[0-9][0-9]\/top\/me\/mahbs\// ) { $endpoint_block = "d2986/top/me/mahbs/*" }
        elsif( $endpoint_block =~ /^d29[0-9][0-9]\/top\/me\/mdmac\// ) { $endpoint_block = "d2986/top/me/mdmac/*" }
        elsif( $endpoint_block =~ /^d29[0-9][0-9]\/top\/me\/mvld\// ) { $endpoint_block = "d2986/top/me/mvld/*" }
        elsif( $endpoint_block =~ /^d29[0-9][0-9]\/top\/me\// ) { $endpoint_block = "d2986/top/me/*" }

        elsif( $endpoint_block =~ /^d29[0-9][0-9]\/top\/sc\/scpu\// ) { $endpoint_block = "d2986/top/sc/scpu (CPU_MAIN)" }
        elsif( $endpoint_block =~ /^d29[0-9][0-9]\/top\/sc\/scpu_wrap\/scpu\// ) { $endpoint_block = "d2986/top/sc/scpu_wrap/scpu (CPU_MAIN_WRAP)" }
        elsif( $endpoint_block =~ /^d29[0-9][0-9]\/top\/sc\/saw_a\// ) { $endpoint_block = "d2986/top/sc/saw_a (aw_a)" }
        elsif( $endpoint_block =~ /^d29[0-9][0-9]\/top\/sc\/semc1\/emc_io_wrapper\// ) { $endpoint_block = "d2986/top/sc/semc1/emc_io_wrapper (EMC_DDR_IO_WRAPPER_R2P0)" }
        elsif( $endpoint_block =~ /^d29[0-9][0-9]\/top\/sc\/skirk\// ) { $endpoint_block = "d2986/top/sc/skirk/*" }
        elsif( $endpoint_block =~ /^d29[0-9][0-9]\/top\/sc\/sata\// ) { $endpoint_block = "d2986/top/sc/sata/*" }
        elsif( $endpoint_block =~ /^d29[0-9][0-9]\/top\/sc\/satahdd\// ) { $endpoint_block = "d2986/top/sc/satahdd/*" }
        elsif( $endpoint_block =~ /^d29[0-9][0-9]\/top\/sc\/smrom\// ) { $endpoint_block = "d2986/top/sc/smrom/*" }
        elsif( $endpoint_block =~ /^d29[0-9][0-9]\/top\/sc\/sahbm\// ) { $endpoint_block = "d2986/top/sc/sahbm/*" }
        elsif( $endpoint_block =~ /^d29[0-9][0-9]\/top\/sc\/sahbs\// ) { $endpoint_block = "d2986/top/sc/sahbs/*" }
        elsif( $endpoint_block =~ /^d29[0-9][0-9]\/top\/sc\/sdmac0\// ) { $endpoint_block = "d2986/top/sc/sdmac0/*" }
        elsif( $endpoint_block =~ /^d29[0-9][0-9]\/top\/sc\/sdmac1\// ) { $endpoint_block = "d2986/top/sc/sdmac1/*" }
        elsif( $endpoint_block =~ /^d29[0-9][0-9]\/top\/sc\/sdmac2\// ) { $endpoint_block = "d2986/top/sc/sdmac2/*" }
        elsif( $endpoint_block =~ /^d29[0-9][0-9]\/top\/sc\/sms1\// ) { $endpoint_block = "d2986/top/sc/sms1/*" }
        elsif( $endpoint_block =~ /^d29[0-9][0-9]\/top\/sc\/sms2\// ) { $endpoint_block = "d2986/top/sc/sms2/*" }
        elsif( $endpoint_block =~ /^d29[0-9][0-9]\/top\/sc\/spmem\// ) { $endpoint_block = "d2986/top/sc/spmem/*" }
        elsif( $endpoint_block =~ /^d29[0-9][0-9]\/top\/sc\/sshr\// ) { $endpoint_block = "d2986/top/sc/sshr/*" }
        elsif( $endpoint_block =~ /^d29[0-9][0-9]\/top\/sc\/susb\// ) { $endpoint_block = "d2986/top/sc/susb/*" }
        elsif( $endpoint_block =~ /^d29[0-9][0-9]\/top\/sc\// ) { $endpoint_block = "d2986/top/sc/*" }

        elsif( $endpoint_block =~ /^d29[0-9][0-9]\/top\/pb\/pspi2\// ) { $endpoint_block = "d2986/top/me/pspi2/*" }
        elsif( $endpoint_block =~ /^d29[0-9][0-9]\/top\/pb\/pmib\// ) { $endpoint_block = "d2986/top/pb/pmib/*" }
        elsif( $endpoint_block =~ /^d29[0-9][0-9]\/top\/pb\// ) { $endpoint_block = "d2986/top/pb/*" }

        elsif( $endpoint_block =~ /^d29[0-9][0-9]\/top\/ck\// ) { $endpoint_block = "d2986/top/ck/*" }
        elsif( $endpoint_block =~ /^d29[0-9][0-9]\/top\/pll\// ) { $endpoint_block = "d2986/top/pll/*" }
        elsif( $endpoint_block =~ /^d29[0-9][0-9]\/top\/dbtest\// ) { $endpoint_block = "d2986/top/dbtest/*" }
        elsif( $endpoint_block =~ /^d29[0-9][0-9]\/top\/fuse\// ) { $endpoint_block = "d2986/top/fuse/*" }
        elsif( $endpoint_block =~ /^d29[0-9][0-9]\/top\/BPM[^\/]+\// ) { $endpoint_block = "d2986/top/BPM*" }
        elsif( $endpoint_block =~ /^d29[0-9][0-9]\/top\// ) { $endpoint_block = "d2986/top/*" }
        elsif( $endpoint_block =~ /^d29[0-9][0-9]\/[^\/]+_SF_reg\// ) { $endpoint_block = "d2986/*_SF_reg" }
        elsif( $endpoint_block =~ /^d29[0-9][0-9]\// ) { $endpoint_block = "d2986/*" }
        elsif( $endpoint_block =~ /^Venus\// ) { $endpoint_block = "Venus/*" }
        elsif( $endpoint_block =~ /^mercury\// ) { $endpoint_block = "mercury" }
        else { $endpoint_block = "*" }
      }
    ##### ONLY FOR DJIN #####
    } elsif( $design eq "DJINIO" ) {
      if( $endpoint_pin !~ /\// ) {
        $endpoint_block = "out" ;
      } elsif( $endpoint_pin =~ /\/SC900DRM[^\/]+\/[^\/]+$/i ) {
        $endpoint_block = "DRAM" ;
      } elsif( $endpoint_pin =~ /\/LV[12]P[^\/]+\/[^\/]+$/ ) {
        $endpoint_block = "SRAM" ;
      } elsif( $endpoint_pin =~ /FUSEBOX/ ) {
        $endpoint_block = "FUSEBOX" ;
      } elsif( $endpoint_pin =~ /\/(CL|PR)$/ ) {
        $endpoint_block = "**async_default**" ;
      } elsif( $endpoint_pin =~ /_clockgating_[^\/]+\/EN$/ ) {
        $endpoint_block = "CG(EN)" ;
      } elsif( $endpoint_pin =~ /_clockgating_[^\/]+\/T$/ ) {
        $endpoint_block = "CG(T)" ;
      } elsif( $endpoint_pin =~ /\/[^\/]+_CG\/EN$/ ) {
        $endpoint_block = "CG(EN)" ;
      } elsif( $endpoint_pin =~ /\/[^\/]+_CG\/T$/ ) {
        $endpoint_block = "CG(T)" ;
      } elsif( $endpoint_pin =~ /\/SE$/ ) {
        $endpoint_block = "DRAM(SE)" ;
      } elsif( $endpoint_pin =~ /\/[^\/]+reg[^\/]*\/S$/ ) {
        $endpoint_block = "DFF(SE)" ;
      } elsif( $endpoint_pin =~ /\/SPARECELL_DFF[0-9][0-9]\/S$/ ) {
        $endpoint_block = "DFF(SE)" ;
      } elsif( $endpoint_pin =~ /\/SCAN_DUMMY[0-9][0-9]\/S$/ ) {
        $endpoint_block = "DFF(SE)" ;
      } elsif( $endpoint_pin =~ /\/[^\/]+reg[^\/]*\/SI$/ ) {
        $endpoint_block = "DFF(SI)" ;
      } elsif( $endpoint_pin =~ /_collar\/[^\/]+_FLOP_reg/ ) {
        $endpoint_block = "DFF(MBIST)" ;
      } elsif( $endpoint_pin =~ /\/[^\/]+reg[^\/]*\/EN$/ ) {
        $endpoint_block = "DFF(EN)" ;
      } elsif( $endpoint_pin =~ /\/[^\/]+reg[^\/]*\/D$/ ) {
        $endpoint_block = "DFF" ;
      } else {
        $endpoint_block = "?" ;
      }
    ##### ONLY FOR HYDRA2IO #####
    } elsif( $design eq "HYDRA2IO" ) {
      if( $endpoint_pin !~ /\// ) {
        $endpoint_block = "out" ;
     #} elsif( $endpoint_pin =~ /^hydra2_0\/kcore_0\// ) {
     #  $endpoint_block = "KCORE" ;
     #} elsif( $endpoint_pin =~ /^hydra2_0\/dcore_0\/dcofdm1_0\// ) {
     #  $endpoint_block = "DCOFDM1" ;
      } elsif( $endpoint_pin =~ /^TACOTAPC/ ) {
        $endpoint_block = "*TAPC*" ;
      } elsif( $endpoint_pin =~ /^[A-Z0-9]+_0_[A-Z0-9]+\/(SF|UP)_reg\// ) {
        $endpoint_block = "*BSC*" ;
      } elsif( $endpoint_pin =~ /^([^\/]+\/[^\/]+)\/\S+/ ) {
        $endpoint_block = $endpoint_pin ;
        $endpoint_block =~ s/^([^\/]+\/[^\/]+)\/\S+$/\1\/\*/ ;
      } else {
        $endpoint_block = "*TOP*" ;
      }
    ##### ONLY FOR MCTEG0 #####
    } elsif( $design eq "MCTEG0" ) {
      if(      $endpoint_pin !~ /\// ) {
               $endpoint_block = "out" ;
      } elsif( $endpoint_pin =~ /^topl\/DDRCONE\/emc\/EMC_DDR_IO_WRAPPER_R2P0\/emc_ddr_io\// ) {
               $endpoint_block = "emc_ddr_io/*" ;
      } else {
               $endpoint_block = $endpoint_pin ;
              #$endpoint_block =~ s/\/.*$// ;
              #$endpoint_block =~ s/^([^\/]+)\/\S+$/\1\/\*/ ;
               $endpoint_block =~ s/^([^\/]+\/[^\/]+)\/\S+$/\1\/\*/ ;
      }
    ##### ONLY FOR SDCHIP ##### 
    } elsif( $design eq "top" ) {
      if(      $endpoint_pin !~ /\// ) {
               $endpoint_block = "out" ;
      } elsif( $endpoint_pin =~ /^ahb2apb_/ ) {
               $endpoint_block = "ahb2apb_*" ;
      } elsif( $endpoint_pin =~ /^(ahb_[^_\/]+_).*$/ ) {
               $endpoint_block = $endpoint_pin ;
               $endpoint_block =~ s/^(ahb_[^_\/]+_).*$/\1_\*/ ; 
      } elsif( $endpoint_pin =~ /^(apb_[^_\/]+_).*$/ ) {
               $endpoint_block = $endpoint_pin ;
               $endpoint_block =~ s/^(apb_[^_\/]+_).*$/\1_\*/ ;
      } elsif( $endpoint_pin =~ /^([^\/]+)\/\S+/ ) {
               $endpoint_block = $endpoint_pin ;
               $endpoint_block =~ s/^([^\/]+)\/\S+$/\1\/\*/ ;
      } else {
               $endpoint_block = "*TOP*" ; 
      } 
    ##### ONLY FOR RODEO6 #####
    } elsif( $design eq "rodeo6" ) {
      if(      $endpoint_pin !~ /\// ) {
               $endpoint_block = "out" ;
      } elsif( $endpoint_pin   =~  /^(rodeo6_top)\/(backend|top_mcu|gcg)\/([^\/]+)\/(\S+)$/ ) {
               $endpoint_block = $endpoint_pin ;
               $endpoint_block =~ s/^(rodeo6_top)\/(backend|top_mcu|gcg)\/([^\/]+)\/(\S+)$/\2\/\3\/\*/ ;
      } elsif( $endpoint_pin   =~  /^(rodeo6_top)\/([^\/]+)\/(\S+)$/ ) {
               $endpoint_block = $endpoint_pin ;
               $endpoint_block =~ s/^(rodeo6_top)\/([^\/]+)\/(\S+)$/\2\/\*/ ;
      } else {
               $endpoint_block = "*TOP*" ;
      }
      ##### ONLY FOR T2CD #####
      } elsif( $design eq "d2993" ) {
        $endpoint_block = $endpoint_pin ;
        if( $endpoint_pin !~ /\// ) { $endpoint_block = "out" }
        elsif( $endpoint_pin   =~  /^top\/me\/mavc\// ) { $endpoint_block = "top/me/mavc (A1RING)" }
        elsif( $endpoint_pin   =~  /^top\/me\/mvme\// ) { $endpoint_block = "top/me/mvme (VETOP)" }
        elsif( $endpoint_pin   =~  /^top\/me\/mcpu\// ) { $endpoint_block = "top/me/mcpu (CPU_MEDIA)" }
        elsif( $endpoint_pin   =~  /^top\/sc\/scpu\// ) { $endpoint_block = "top/sc/scpu (CPU_MAIN)" }
        elsif( $endpoint_pin   =~  /^top\/sc\/saw_a\// ) { $endpoint_block = "top/sc/saw_a (aw_)" }
        elsif( $endpoint_pin   =~  /^top\/sc\/semc1\/emc_io_wrapper\// ) { $endpoint_block = "top/sc/semc1/emc_io_wrapper (EMC_DDR_IO_WRAPPER_R2P0)" }
        elsif( $endpoint_pin   =~  /^top\/ck\// ) { $endpoint_block = "top/ck (ck)" }
        elsif( $endpoint_pin   =~  /^[^\/]+_[A-Z]+\/[A-Z]+_reg\// ) { $endpoint_block = "*BSC*" }
        else { $endpoint_block = "*TOP*" }
      } elsif( $design eq "t2cd" ) {
        $endpoint_block = $endpoint_pin ;
        if( $endpoint_pin !~ /\// ) { $endpoint_block = "out" }
        elsif( $endpoint_pin   =~  /^d2993\/top\/me\/mavc\// ) { $endpoint_block = "d2993/top/me/mavc (A1RING)" }
        elsif( $endpoint_pin   =~  /^d2993\/top\/me\/mvme\// ) { $endpoint_block = "d2993/top/me/mvme (VETOP)" }
        elsif( $endpoint_pin   =~  /^d2993\/top\/me\/mcpu\// ) { $endpoint_block = "d2993/top/me/mcpu (CPU_MEDIA)" }
        elsif( $endpoint_pin   =~  /^d2993\/top\/sc\/scpu\// ) { $endpoint_block = "d2993/top/sc/scpu (CPU_MAIN)" }
        elsif( $endpoint_pin   =~  /^d2993\/top\/sc\/saw_a\// ) { $endpoint_block = "d2993/top/sc/saw_a (aw_)" }
        elsif( $endpoint_pin   =~  /^d2993\/top\/sc\/semc1\/emc_io_wrapper\// ) { $endpoint_block = "d2993/top/sc/semc1/emc_io_wrapper (EMC_DDR_IO_WRAPPER_R2P0)" }
        elsif( $endpoint_pin   =~  /^d2993\/top\/ck\// ) { $endpoint_block = "d2993/top/ck (ck)" }
        elsif( $endpoint_pin   =~  /^d2993\/[^\/]+_[A-Z]+\/[A-Z]+_reg\// ) { $endpoint_block = "*BSC*" }
        elsif( $endpoint_pin   =~  /^cdram\// ) { $endpoint_block = "cdram (cdram)" }
        else { $endpoint_block = "*TOP*" }
      ##### ONLY FOR HYDRA5 #####
      } elsif( $design eq "HYDRA5IO" ) {
        $endpoint_block = $endpoint_pin ;
        if( $endpoint_pin !~ /\// ) { $endpoint_block = "out" }
        elsif( $endpoint_block =~ /^hydra5_0\/(\w+_0\/\w+_0)\/\S+$/ ) { $endpoint_block =~ s/^hydra5_0\/(\w+_0\/\w+_0)\/\S+$/\1\/\*/ }
        elsif( $endpoint_block =~ /^hydra5_0\/(\w+_0)\/\S+$/ ) { $endpoint_block =~ s/^hydra5_0\/(\w+_0)\/\S+$/\1\/\*/ }
        else { $endpoint_block = "*TOP*" }
      } elsif( $design eq "D4191" ) {
        $endpoint_block = $endpoint_pin ;
        if( $endpoint_pin !~ /\// ) { $endpoint_block = "out" }
        elsif( $endpoint_block =~ /^(mbcon_[^\/]+)\/\S+$/ ) { $endpoint_block =~ s/^(mbcon_[^\/]+)\/\S+$/\1\/\*/ }
        elsif( $endpoint_block =~ /^(\w+\/\w+\/\w+)\/\S+$/ ) { $endpoint_block =~ s/^(\w+\/\w+\/\w+)\/\S+$/\1\/\*/ }
        elsif( $endpoint_block =~ /^(\w+\/\w+)\/\S+$/      ) { $endpoint_block =~ s/^(\w+\/\w+)\/\S+$/\1\/\*/ }
        elsif( $endpoint_block =~ /^(\w+)\/\S+$/           ) { $endpoint_block =~ s/^(\w+)\/\S+$/\1\/\*/ }
        else { $endpoint_block = "*TOP*" }

      # Ganesha
      } elsif( $design eq "ZUDM" ) {
        $endpoint_block = $endpoint_pin ;
        if( $endpoint_pin !~ /\// ) { $endpoint_block = "out" }
        elsif( $endpoint_block =~ /TMC_YV3_DEC_BASE_TOP_02/ ) { $endpoint_block = "TMC_YV3_DEC_BASE_TOP_02" }
        elsif( $endpoint_block =~ /TMC_YV3_DEC_BASE_TOP_13/ ) { $endpoint_block = "TMC_YV3_DEC_BASE_TOP_13" }
        else { $endpoint_block = "ZUDM" }

      } elsif( $design eq "ZTOP" ) {
        $endpoint_block = $endpoint_pin ;
        if( $endpoint_pin !~ /\// ) { $endpoint_block = "out" }
        elsif( $endpoint_block =~ /\/SCSPHY0123\/C0/ ) { $endpoint_block = "SCSPHY0123(0)" }
        elsif( $endpoint_block =~ /\/SCSPHY0123\/C1/ ) { $endpoint_block = "SCSPHY0123(1)" }
        elsif( $endpoint_block =~ /\/SCSPHY0123\/C2/ ) { $endpoint_block = "SCSPHY0123(2)" }
        elsif( $endpoint_block =~ /\/SCSPHY0123\/C3/ ) { $endpoint_block = "SCSPHY0123(3)" }
        elsif( $endpoint_block =~ /\/SCSPHY4567\/C0/ ) { $endpoint_block = "SCSPHY4567(0)" }
        elsif( $endpoint_block =~ /\/SCSPHY4567\/C1/ ) { $endpoint_block = "SCSPHY4567(1)" }
        elsif( $endpoint_block =~ /\/SCSPHY4567\/C2/ ) { $endpoint_block = "SCSPHY4567(2)" }
        elsif( $endpoint_block =~ /\/SCSPHY4567\/C3/ ) { $endpoint_block = "SCSPHY4567(3)" }
        else { $endpoint_block = "*TOP*" }

      } elsif( $design eq "PS02" ) {
        $endpoint_block = $endpoint_pin ;
        if( $endpoint_pin !~ /\// ) { 
          $endpoint_block = "out" ;
        } else {
          $endpoint_block = $endpoint_pin ;

          $endpoint_block =~ s/(BISTCON_FBOX)\S+/${1}/ ;
          $endpoint_block =~ s/(ALCHIP_DFTC_LOGIC)\S+/${1}/ ;
          $endpoint_block =~ s/(ALCHIP_sean_fix)_\S+/${1}_\*/ ;
          $endpoint_block =~ s/(LOCKUP)\S+/${1}\*/ ;
          $endpoint_block =~ s/(RETIMING_FLOP)\S+/${1}\*/ ;
          $endpoint_block =~ s/(SCAN_dummy_reg_post)_\S+/${1}_\*/ ;
          $endpoint_block =~ s/(SCAN_dummy_reg_pre)_\S+/${1}_\*/ ;
          $endpoint_block =~ s/(SNPS_PipeHead)_\S+/${1}_\*/ ;
          $endpoint_block =~ s/(SNPS_PipeTail)_\S+/${1}_\*/ ;
          $endpoint_block =~ s/(udtp)_\S+/${1}_\*/ ;
          $endpoint_block =~ s/(dft_reg)_\S+/${1}_\*/ ;

          $endpoint_block =~ s/^(DCIO_\d+\/p\d+\/phy)\/\S+/${1}/ ;
          $endpoint_block =~ s/^(DCIO_\d+\/c\d+a_wrap\/c\d+)\/\S+/${1}/ ;
          $endpoint_block =~ s/^(STU\/ETH)\/\S+$/${1}/ ;
          $endpoint_block =~ s/^(STU\/MEMIO)\/\S+$/${1}/ ;
          $endpoint_block =~ s/^(STU\/SD0TOP)\/\S+$/${1}/ ;
          $endpoint_block =~ s/^(STU\/SD1TOP)\/\S+$/${1}/ ;
          $endpoint_block =~ s/^(STU\/SD2TOP)\/\S+$/${1}/ ;
          $endpoint_block =~ s/^(ISRX\/LINK_TOP)\/\S+$/${1}/ ;

          $endpoint_block =~ s/^(MCU\/NoC_Top\/i_Mem_Int_Arc_St\/m_PD01)\/\S+$/MCU\(Mem_Int:1\)/ ;
          $endpoint_block =~ s/^(MCU\/NoC_Top\/i_Mem_Int_Arc_St\/m_PD06)\/\S+$/MCU\(Mem_Int:2\)/ ;
          $endpoint_block =~ s/^(MCU\/NoC_Top\/i_Mem_Int_Arc_St\/m_PD30)\/\S+$/MCU\(Mem_Int:3\)/ ;
          $endpoint_block =~ s/^(MCU\/NoC_Top\/i_Mem_Int_Arc_St\/m_PD_DEF01_600\/NIUs_To_Scheduler)\/\S+$/MCU\(Mem_Int:4\)/ ;
          $endpoint_block =~ s/^(MCU\/NoC_Top\/i_S_MainNoC_Arc_St\/m_PD_A10)\/\S+$/MCU\(MainNoC:NIU\)/ ;
          $endpoint_block =~ s/^(MCU\/NoC_Top\/i_S_MainNoC_Arc_St\/m_PD_A35)\/\S+$/MCU\(MainNoC:NIU\)/ ;
          $endpoint_block =~ s/^(MCU\/NoC_Top\/i_S_MainNoC_Arc_St\/m_PD_A36)\/\S+$/MCU\(MainNoC:NIU\)/ ;
          $endpoint_block =~ s/^(MCU\/NoC_Top\/i_S_MainNoC_Arc_St\/m_PD_A39)\/\S+$/MCU\(MainNoC:NIU\)/ ;
          $endpoint_block =~ s/^(MCU\/NoC_Top\/i_S_MainNoC_Arc_St\/m_PD_B12)\/\S+$/MCU\(MainNoC:NIU\)/ ;
          $endpoint_block =~ s/^(MCU\/NoC_Top\/i_S_MainNoC_Arc_St\/m_PD_B13)\/\S+$/MCU\(MainNoC:NIU\)/ ;
          $endpoint_block =~ s/^(MCU\/NoC_Top\/i_S_MainNoC_Arc_St\/m_PD_C17)\/\S+$/MCU\(MainNoC:NIU\)/ ;
          $endpoint_block =~ s/^(MCU\/NoC_Top\/i_S_MainNoC_Arc_St\/m_PD_C18)\/\S+$/MCU\(MainNoC:NIU\)/ ;
          $endpoint_block =~ s/^(MCU\/NoC_Top\/i_S_MainNoC_Arc_St\/m_PD_C19)\/\S+$/MCU\(MainNoC:NIU\)/ ;
          $endpoint_block =~ s/^(MCU\/NoC_Top\/i_S_MainNoC_Arc_St\/m_PD_D14)\/\S+$/MCU\(MainNoC:NIU\)/ ;
          $endpoint_block =~ s/^(MCU\/NoC_Top\/i_S_MainNoC_Arc_St\/m_PD_D15)\/\S+$/MCU\(MainNoC:NIU\)/ ;
          $endpoint_block =~ s/^(MCU\/NoC_Top\/i_S_MainNoC_Arc_St\/m_PD_D16)\/\S+$/MCU\(MainNoC:NIU\)/ ;
          $endpoint_block =~ s/^(MCU\/NoC_Top\/i_S_MainNoC_Arc_St\/m_PD_DEF00\/NIUs_ODU0)\/\S+$/MCU\(MainNoC:NIU\)/ ;
          $endpoint_block =~ s/^(MCU\/NoC_Top\/i_S_MainNoC_Arc_St\/m_PD_DEF00\/NIUs_PCIe_reg)\/\S+$/MCU\(MainNoC:NIU\)/ ;
          $endpoint_block =~ s/^(MCU\/NoC_Top\/i_S_MainNoC_Arc_St\/m_PD_DEF01\/NIUs_To_ReorderBuffer\/NIU_to_DRAM_0)\/\S+$/MCU\(MainNoC:NIU\)/ ;
          $endpoint_block =~ s/^(MCU\/NoC_Top\/i_S_MainNoC_Arc_St\/m_PD_DEF01\/NIUs_To_ReorderBuffer\/NIU_to_DRAM_1)\/\S+$/MCU\(MainNoC:NIU\)/ ;
          $endpoint_block =~ s/^(MCU\/NoC_Top\/i_S_MainNoC_Arc_St\/m_PD_DEF01\/NIUs_To_ReorderBuffer\/NIU_to_DRAM_4)\/\S+$/MCU\(MainNoC:NIU\)/ ;
          $endpoint_block =~ s/^(MCU\/NoC_Top\/i_S_MainNoC_Arc_St\/m_PD_DEF01\/NIUs_To_ReorderBuffer\/NIU_to_DRAM_5)\/\S+$/MCU\(MainNoC:NIU\)/ ;
          $endpoint_block =~ s/^(MCU\/NoC_Top\/i_S_MainNoC_Arc_St\/m_PD_DEF01\/NIUs_To_ReorderBuffer\/NIU_to_DRAM_6)\/\S+$/MCU\(MainNoC:NIU\)/ ;
          $endpoint_block =~ s/^(MCU\/NoC_Top\/i_S_MainNoC_Arc_St\/m_PD_DEF02\/NIUs_GEVG)\/\S+$/MCU\(MainNoC:NIU\)/ ;
          $endpoint_block =~ s/^(MCU\/NoC_Top\/i_S_MainNoC_Arc_St\/m_PD_DEF06\/NIUs_ADU)\/\S+$/MCU\(MainNoC:NIU\)/ ;
          $endpoint_block =~ s/^(MCU\/NoC_Top\/i_S_MainNoC_Arc_St\/m_PD_DEF06\/NIUs_JPU)\/\S+$/MCU\(MainNoC:NIU\)/ ;
          $endpoint_block =~ s/^(MCU\/NoC_Top\/i_S_MainNoC_Arc_St\/m_PD_DEF06\/NIUs_STU_ETH)\/\S+$/MCU\(MainNoC:NIU\)/ ;
          $endpoint_block =~ s/^(MCU\/NoC_Top\/i_S_MainNoC_Arc_St\/m_PD_DEF06\/NIUs_STU_SD2)\/\S+$/MCU\(MainNoC:NIU\)/ ;
          $endpoint_block =~ s/^(MCU\/NoC_Top\/i_S_MainNoC_Arc_St\/m_PD_DEF07\/NIUs_STU_SD0)\/\S+$/MCU\(MainNoC:NIU\)/ ;
          $endpoint_block =~ s/^(MCU\/NoC_Top\/i_S_MainNoC_Arc_St\/m_PD_DEF07\/NIUs_STU_SD1)\/\S+$/MCU\(MainNoC:NIU\)/ ;
          $endpoint_block =~ s/^(MCU\/NoC_Top\/i_S_MainNoC_Arc_St\/m_PD_DEF07\/NIUs_STU_other_mas)\/\S+$/MCU\(MainNoC:NIU\)/ ;
          $endpoint_block =~ s/^(MCU\/NoC_Top\/i_S_MainNoC_Arc_St\/m_PD_DEF07\/NIUs_STU_other_slv)\/\S+$/MCU\(MainNoC:NIU\)/ ;
          $endpoint_block =~ s/^(MCU\/NoC_Top\/i_S_MainNoC_Arc_St\/m_PD_DEF08\/NIUs_MIU_mas)\/\S+$/MCU\(MainNoC:NIU\)/ ;
          $endpoint_block =~ s/^(MCU\/NoC_Top\/i_S_MainNoC_Arc_St\/m_PD_DEF08\/NIUs_MIU_slv)\/\S+$/MCU\(MainNoC:NIU\)/ ;
          $endpoint_block =~ s/^(MCU\/NoC_Top\/i_S_MainNoC_Arc_St\/m_PD_DEF08\/NIUs_VOU_monm_pro)\/\S+$/MCU\(MainNoC:NIU\)/ ;
          $endpoint_block =~ s/^(MCU\/NoC_Top\/i_S_MainNoC_Arc_St\/m_PD_DEF08\/NIUs_VOU_mont)\/\S+$/MCU\(MainNoC:NIU\)/ ;
          $endpoint_block =~ s/^(MCU\/NoC_Top\/i_S_MainNoC_Arc_St\/m_PD_DEF08\/NIUs_VOU_other_mas)\/\S+$/MCU\(MainNoC:NIU\)/ ;
          $endpoint_block =~ s/^(MCU\/NoC_Top\/i_S_MainNoC_Arc_St\/m_PD_DEF08\/NIUs_VOU_other_slv)\/\S+$/MCU\(MainNoC:NIU\)/ ;
          $endpoint_block =~ s/^(MCU\/NoC_Top\/i_S_MainNoC_Arc_St\/m_PD_DEF08\/NIUs_VOU_sub_mont)\/\S+$/MCU\(MainNoC:NIU\)/ ;
          $endpoint_block =~ s/^(MCU\/NoC_Top\/i_S_MainNoC_Arc_St\/m_PD_DEF09\/NIUs_TCC)\/\S+$/MCU\(MainNoC:NIU\)/ ;
          $endpoint_block =~ s/^(MCU\/NoC_Top\/i_S_MainNoC_Arc_St\/m_PD_F21)\/\S+$/MCU\(MainNoC:NIU\)/ ;
          $endpoint_block =~ s/^(MCU\/NoC_Top\/i_S_MainNoC_Arc_St\/m_PD_F22)\/\S+$/MCU\(MainNoC:NIU\)/ ;
          $endpoint_block =~ s/^(MCU\/NoC_Top\/i_S_MainNoC_Arc_St\/m_PD_F23_0)\/\S+$/MCU\(MainNoC:NIU\)/ ;
          $endpoint_block =~ s/^(MCU\/NoC_Top\/i_S_MainNoC_Arc_St\/m_PD_F23_1)\/\S+$/MCU\(MainNoC:NIU\)/ ;
          $endpoint_block =~ s/^(MCU\/NoC_Top\/i_S_MainNoC_Arc_St\/m_PD_F24_f32)\/\S+$/MCU\(MainNoC:NIU\)/ ;
          $endpoint_block =~ s/^(MCU\/NoC_Top\/i_S_MainNoC_Arc_St\/m_PD_F24_f4)\/\S+$/MCU\(MainNoC:NIU\)/ ;
          $endpoint_block =~ s/^(MCU\/NoC_Top\/i_S_MainNoC_Arc_St\/m_PD_F24_uec)\/\S+$/MCU\(MainNoC:NIU\)/ ;
          $endpoint_block =~ s/^(MCU\/NoC_Top\/i_S_MainNoC_Arc_St\/m_PD_F24_ume)\/\S+$/MCU\(MainNoC:NIU\)/ ;
          $endpoint_block =~ s/^(MCU\/NoC_Top\/i_S_MainNoC_Arc_St\/m_PD_F24_usc)\/\S+$/MCU\(MainNoC:NIU\)/ ;
          $endpoint_block =~ s/^(MCU\/NoC_Top\/i_S_MainNoC_Arc_St\/m_PD_H20)\/\S+$/MCU\(MainNoC:NIU\)/ ;
          $endpoint_block =~ s/^(MCU\/NoC_Top\/i_S_MainNoC_Arc_St\/m_PD_J07)\/\S+$/MCU\(MainNoC:NIU\)/ ;
          $endpoint_block =~ s/^(MCU\/NoC_Top\/i_S_MainNoC_Arc_St\/m_PD_L33)\/\S+$/MCU\(MainNoC:NIU\)/ ;
          $endpoint_block =~ s/^(MCU\/NoC_Top\/i_S_MainNoC_Arc_St\/m_PD_L34)\/\S+$/MCU\(MainNoC:NIU\)/ ;
          $endpoint_block =~ s/^(MCU\/NoC_Top\/i_S_MainNoC_Arc_St\/m_PD_U08_0)\/\S+$/MCU\(MainNoC:NIU\)/ ;
          $endpoint_block =~ s/^(MCU\/NoC_Top\/i_S_MainNoC_Arc_St\/m_PD_V28)\/\S+$/MCU\(MainNoC:NIU\)/ ;
          $endpoint_block =~ s/^(MCU\/NoC_Top\/i_S_MainNoC_Arc_St\/m_PD_V29)\/\S+$/MCU\(MainNoC:NIU\)/ ;
          $endpoint_block =~ s/^(MCU\/NoC_Top\/i_S_PeriNoC_Arc_St\/m_PD_B12)\/\S+$/MCU\(PeriNoC:NIU\)/ ;
          $endpoint_block =~ s/^(MCU\/NoC_Top\/i_S_PeriNoC_Arc_St\/m_PD_B13)\/\S+$/MCU\(PeriNoC:NIU\)/ ;
          $endpoint_block =~ s/^(MCU\/NoC_Top\/i_S_PeriNoC_Arc_St\/m_PD_C14)\/\S+$/MCU\(PeriNoC:NIU\)/ ;
          $endpoint_block =~ s/^(MCU\/NoC_Top\/i_S_PeriNoC_Arc_St\/m_PD_C15)\/\S+$/MCU\(PeriNoC:NIU\)/ ;
          $endpoint_block =~ s/^(MCU\/NoC_Top\/i_S_PeriNoC_Arc_St\/m_PD_C16)\/\S+$/MCU\(PeriNoC:NIU\)/ ;
          $endpoint_block =~ s/^(MCU\/NoC_Top\/i_S_PeriNoC_Arc_St\/m_PD_C17)\/\S+$/MCU\(PeriNoC:NIU\)/ ;
          $endpoint_block =~ s/^(MCU\/NoC_Top\/i_S_PeriNoC_Arc_St\/m_PD_C19)\/\S+$/MCU\(PeriNoC:NIU\)/ ;
          $endpoint_block =~ s/^(MCU\/NoC_Top\/i_S_PeriNoC_Arc_St\/m_PD_DEF00\/NIU_ISRX)\/\S+$/MCU\(PeriNoC:NIU\)/ ;
          $endpoint_block =~ s/^(MCU\/NoC_Top\/i_S_PeriNoC_Arc_St\/m_PD_DEF00\/NIUs_ODU0)\/\S+$/MCU\(PeriNoC:NIU\)/ ;
          $endpoint_block =~ s/^(MCU\/NoC_Top\/i_S_PeriNoC_Arc_St\/m_PD_DEF00\/NIUs_PCIe_reg)\/\S+$/MCU\(PeriNoC:NIU\)/ ;
          $endpoint_block =~ s/^(MCU\/NoC_Top\/i_S_PeriNoC_Arc_St\/m_PD_DEF01\/NIUs_DCIO_0)\/\S+$/MCU\(PeriNoC:NIU\)/ ;
          $endpoint_block =~ s/^(MCU\/NoC_Top\/i_S_PeriNoC_Arc_St\/m_PD_DEF02\/NIUs_GEVG)\/\S+$/MCU\(PeriNoC:NIU\)/ ;
          $endpoint_block =~ s/^(MCU\/NoC_Top\/i_S_PeriNoC_Arc_St\/m_PD_DEF03\/NIUs_MCU)\/\S+$/MCU\(PeriNoC:NIU\)/ ;
          $endpoint_block =~ s/^(MCU\/NoC_Top\/i_S_PeriNoC_Arc_St\/m_PD_DEF05\/NIUs_PCIe_reg)\/\S+$/MCU\(PeriNoC:NIU\)/ ;
          $endpoint_block =~ s/^(MCU\/NoC_Top\/i_S_PeriNoC_Arc_St\/m_PD_DEF06\/NIUs_ADU)\/\S+$/MCU\(PeriNoC:NIU\)/ ;
          $endpoint_block =~ s/^(MCU\/NoC_Top\/i_S_PeriNoC_Arc_St\/m_PD_DEF06\/NIUs_DITX)\/\S+$/MCU\(PeriNoC:NIU\)/ ;
          $endpoint_block =~ s/^(MCU\/NoC_Top\/i_S_PeriNoC_Arc_St\/m_PD_DEF06\/NIUs_JPU)\/\S+$/MCU\(PeriNoC:NIU\)/ ;
          $endpoint_block =~ s/^(MCU\/NoC_Top\/i_S_PeriNoC_Arc_St\/m_PD_DEF06\/NIUs_LCU)\/\S+$/MCU\(PeriNoC:NIU\)/ ;
          $endpoint_block =~ s/^(MCU\/NoC_Top\/i_S_PeriNoC_Arc_St\/m_PD_DEF06\/NIUs_STU_ETH)\/\S+$/MCU\(PeriNoC:NIU\)/ ;
          $endpoint_block =~ s/^(MCU\/NoC_Top\/i_S_PeriNoC_Arc_St\/m_PD_DEF06\/NIUs_STU_SD2)\/\S+$/MCU\(PeriNoC:NIU\)/ ;
          $endpoint_block =~ s/^(MCU\/NoC_Top\/i_S_PeriNoC_Arc_St\/m_PD_DEF07\/NIUs_HDMI)\/\S+$/MCU\(PeriNoC:NIU\)/ ;
          $endpoint_block =~ s/^(MCU\/NoC_Top\/i_S_PeriNoC_Arc_St\/m_PD_DEF07\/NIUs_STU_SD0)\/\S+$/MCU\(PeriNoC:NIU\)/ ;
          $endpoint_block =~ s/^(MCU\/NoC_Top\/i_S_PeriNoC_Arc_St\/m_PD_DEF07\/NIUs_STU_SD1)\/\S+$/MCU\(PeriNoC:NIU\)/ ;
          $endpoint_block =~ s/^(MCU\/NoC_Top\/i_S_PeriNoC_Arc_St\/m_PD_DEF07\/NIUs_STU_other_slv)\/\S+$/MCU\(PeriNoC:NIU\)/ ;
          $endpoint_block =~ s/^(MCU\/NoC_Top\/i_S_PeriNoC_Arc_St\/m_PD_DEF08\/NIUs_MIU_slv)\/\S+$/MCU\(PeriNoC:NIU\)/ ;
          $endpoint_block =~ s/^(MCU\/NoC_Top\/i_S_PeriNoC_Arc_St\/m_PD_DEF08\/NIUs_MIU_slv_APB_I4)\/\S+$/MCU\(PeriNoC:NIU\)/ ;
          $endpoint_block =~ s/^(MCU\/NoC_Top\/i_S_PeriNoC_Arc_St\/m_PD_DEF08\/NIUs_MIU_slv_APB_I9)\/\S+$/MCU\(PeriNoC:NIU\)/ ;
          $endpoint_block =~ s/^(MCU\/NoC_Top\/i_S_PeriNoC_Arc_St\/m_PD_DEF08\/NIUs_PMU)\/\S+$/MCU\(PeriNoC:NIU\)/ ;
          $endpoint_block =~ s/^(MCU\/NoC_Top\/i_S_PeriNoC_Arc_St\/m_PD_DEF08\/NIUs_SSG)\/\S+$/MCU\(PeriNoC:NIU\)/ ;
          $endpoint_block =~ s/^(MCU\/NoC_Top\/i_S_PeriNoC_Arc_St\/m_PD_DEF09\/NIUs_TCC)\/\S+$/MCU\(PeriNoC:NIU\)/ ;
          $endpoint_block =~ s/^(MCU\/NoC_Top\/i_S_PeriNoC_Arc_St\/m_PD_DEF11\/NIUs_CKG)\/\S+$/MCU\(PeriNoC:NIU\)/ ;
          $endpoint_block =~ s/^(MCU\/NoC_Top\/i_S_PeriNoC_Arc_St\/m_PD_H20)\/\S+$/MCU\(PeriNoC:NIU\)/ ;
          $endpoint_block =~ s/^(MCU\/NoC_Top\/i_S_PeriNoC_Arc_St\/m_PD_J07)\/\S+$/MCU\(PeriNoC:NIU\)/ ;
          $endpoint_block =~ s/^(MCU\/NoC_Top\/i_S_PeriNoC_Arc_St\/m_PD_L33)\/\S+$/MCU\(PeriNoC:NIU\)/ ;
          $endpoint_block =~ s/^(MCU\/NoC_Top\/i_S_PeriNoC_Arc_St\/m_PD_L34)\/\S+$/MCU\(PeriNoC:NIU\)/ ;
          $endpoint_block =~ s/^(MCU\/NoC_Top\/i_S_PeriNoC_Arc_St\/m_PD_T01)\/\S+$/MCU\(PeriNoC:NIU\)/ ;
          $endpoint_block =~ s/^(MCU\/NoC_Top\/i_S_PeriNoC_Arc_St\/m_PD_T06)\/\S+$/MCU\(PeriNoC:NIU\)/ ;
          $endpoint_block =~ s/^(MCU\/NoC_Top\/i_S_PeriNoC_Arc_St\/m_PD_T30)\/\S+$/MCU\(PeriNoC:NIU\)/ ;
          $endpoint_block =~ s/^(MCU\/NoC_Top\/i_S_PeriNoC_Arc_St\/m_PD_U08_0)\/\S+$/MCU\(PeriNoC:NIU\)/ ;
          $endpoint_block =~ s/^(MCU\/NoC_Top\/i_S_PeriNoC_Arc_St\/m_PD_V28)\/\S+$/MCU\(PeriNoC:NIU\)/ ;
          $endpoint_block =~ s/^(MCU\/NoC_Top\/i_S_PeriNoC_Arc_St\/m_PD_V29)\/\S+$/MCU\(PeriNoC:NIU\)/ ;

          if( $detail_mcu_group == 1 ) {
          $endpoint_block =~   s/^(MCU\/NoC_Top\/i_Mem_Int_Arc_St)\/m_PD_(DEF\d+)\S+$/MCU\(Mem_Int:4\)/ ;
          $endpoint_block =~ s/^(MCU\/NoC_Top\/i_S_MainNoC_Arc_St)\/m_PD_(DEF\d+)\S+$/MCU\(MainNoC:\2\)/ ;
          $endpoint_block =~ s/^(MCU\/NoC_Top\/i_S_PeriNoC_Arc_St)\/m_PD_(DEF\d+)\S+$/MCU\(PeriNoC:\2\)/ ;
          $endpoint_block =~ s/^(MCU\/NoC_Top\/i_S_MainNoC_Arc_St)\/\S+$/MCU\(MainNoC\)/ ;
          $endpoint_block =~ s/^(MCU\/NoC_Top\/i_S_PeriNoC_Arc_St)\/\S+$/MCU\(PeriNoC\)/ ;
          }

          $endpoint_block =~ s/\/.*$// if( $endpoint_block eq $endpoint_pin ) ;
        }
      } elsif( $design eq "VP1" ) {
        $endpoint_block = $endpoint_pin ;
        if( $endpoint_pin !~ /\// ) {
          $endpoint_block = "out" ;
        } else {
          $endpoint_block = $endpoint_pin ;

         #$endpoint_block =~ s/(BISTCON_FBOX)\S+/${1}/ ;
         #$endpoint_block =~ s/(ALCHIP_DFTC_LOGIC)\S+/${1}/ ;
         #$endpoint_block =~ s/(ALCHIP_sean_fix)_\S+/${1}_\*/ ;
         #$endpoint_block =~ s/(LOCKUP)\S+/${1}\*/ ;
         #$endpoint_block =~ s/(RETIMING_FLOP)\S+/${1}\*/ ;
         #$endpoint_block =~ s/(SCAN_dummy_reg_post)_\S+/${1}_\*/ ;
         #$endpoint_block =~ s/(SCAN_dummy_reg_pre)_\S+/${1}_\*/ ;
         #$endpoint_block =~ s/(SNPS_PipeHead)_\S+/${1}_\*/ ;
         #$endpoint_block =~ s/(SNPS_PipeTail)_\S+/${1}_\*/ ;
         #$endpoint_block =~ s/(udtp)_\S+/${1}_\*/ ;
         #$endpoint_block =~ s/(dft_reg)_\S+/${1}_\*/ ;

          $endpoint_block =~ s/^(CORE\/CPUPERI\/HTOP\/HBUSTOP)\/\S+/${1}/ ;
          $endpoint_block =~ s/^(CORE\/CPUPERI\/HCPU)\/\S+/${1}/ ;
          $endpoint_block =~ s/^(CORE\/CPUPERI\/USB20TOP\/USB20_OLS\/USB20_ILS)\/\S+/${1}/ ;
          $endpoint_block =~ s/^(CORE\/CPUPERI\/USB30TOP\/USB30_OLS\/USB30_ILS)\/\S+/${1}/ ;
          $endpoint_block =~ s/^(CORE\/MBUSTOP\/MBUSTOP_CORE\/DDRB\/DDRB[01]\/U_DDR_PHY)\/\S+/${1}/ ;
          $endpoint_block =~ s/^(CORE\/MBUSTOP\/MBUSTOP_CORE)\/\S+/${1}/ if( $endpoint_block !~ /^(CORE\/MBUSTOP\/MBUSTOP_CORE\/DDRB\/DDRB[012]\/U_DDR_PHY)/ ) ;
          $endpoint_block =~ s/^(CORE\/VPU\/VBE_TOP\/vbe[012]\/pl)\/\S+/${1}/ ;
          $endpoint_block =~ s/^(CORE\/VPU\/VBE_TOP)\/\S+/${1}/ if( $endpoint_block !~ /^(CORE\/VPU\/VBE_TOP\/vbe[012]\/pl)/ ) ;
          $endpoint_block =~ s/^(CORE\/VPU\/RPP)\/\S+/${1}/ ;
          $endpoint_block =~ s/^(CORE\/VPU\/SPP\/SPP0\/S[ABC]ISP\/MIPIRX[01]_TOP\/CSI2M2S2_OLS\/CSI2M2S2_ILS)\/\S+/${1}/ ;
          $endpoint_block =~ s/^(CORE\/VPU\/SPP\/SPP1\/S[DEF]ISP\/MIPIRX[01]_TOP\/CSI2M2S2_OLS\/CSI2M2S2_ILS)\/\S+/${1}/ ;
          $endpoint_block =~ s/^(CORE\/VPU\/SPP\/SPP0)\/\S+/${1}/ if( $endponit_block !~ /^(CORE\/VPU\/SPP\/SPP0\/S[ABC]ISP\/MIPIRX[01]_TOP\/CSI2M2S2_OLS\/CSI2M2S2_ILS)/ ) ;
          $endpoint_block =~ s/^(CORE\/VPU\/SPP\/SPP1)\/\S+/${1}/ if( $endponit_block !~ /^(CORE\/VPU\/SPP\/SPP0\/S[DEF]ISP\/MIPIRX[01]_TOP\/CSI2M2S2_OLS\/CSI2M2S2_ILS)/ ) ;

          $endpoint_block =~ s/\/.*$// if( $endpoint_block eq $endpoint_pin ) ;
        }
      } elsif( $design eq "VBE_PL" ) {
        $endpoint_block = $endpoint_pin ;
        if( $endpoint_pin !~ /\// ) {
          $endpoint_block = "out" ;
        } else {
          $endpoint_block = $endpoint_pin ;

          $endpoint_block =~ s/^(pd\/cd\/[^\/]+)\/\S+/${1}\/\*/                   if( $endpoint_block !~ /^(pd\/cd\/core)\// ) ;
          $endpoint_block =~ s/^(pd\/cd\/core\/[^\/]+)\/\S+/${1}\/\*/             if( $endpoint_block !~ /^(pd\/cd\/core\/vp6)\// ) ;
          $endpoint_block =~ s/^(pd\/cd\/core\/vp6\/[^\/]+)\/\S+/${1}\/\*/        if( $endpoint_block !~ /^(pd\/cd\/core\/vp6\/xtmem)\// ) ;
          $endpoint_block =~ s/^(pd\/cd\/core\/vp6\/xtmem)\/\S+/${1}\/\*/         if( $endpoint_block !~ /^(pd\/cd\/core\/vp6\/xtmem)\/(Xttop|dram0|dram1|icache|iram0|itag)\// ) ;
          $endpoint_block =~ s/^(pd\/cd\/core\/vp6\/xtmem\/[^\/]+)\/\S+/${1}\/\*/ if( $endpoint_block =~ /^(pd\/cd\/core\/vp6\/xtmem)\/(Xttop|dram0|dram1|icache|iram0|itag)\// ) ;

          $endpoint_block =~ s/\/.*$// if( $endpoint_block eq $endpoint_pin ) ;
        }
      } elsif( $design eq "HCPU" ) {
        $endpoint_block = $endpoint_pin ;
        if( $endpoint_pin !~ /\// ) {
          $endpoint_block = "out" ;
        } else {
          $endpoint_block = $endpoint_pin ;

          $endpoint_block =~ s/^a9mp_top\/u_a9mp_pwrwrp_OLS\/u_a9mp_pwrwrp_ILS\/u_a9mp_wholewrp\/u_a9mp_testwrp\/u_a9mp_corewrp\/(u_CORTEXA9INTEGRATION\/u_falcon\/u_cpu0)\/\S+/...\/${1}\/\*/ if( $endpoint_block !~ /\/\*/ ) ;
          $endpoint_block =~ s/^a9mp_top\/u_a9mp_pwrwrp_OLS\/u_a9mp_pwrwrp_ILS\/u_a9mp_wholewrp\/u_a9mp_testwrp\/u_a9mp_corewrp\/(u_CORTEXA9INTEGRATION\/u_falcon\/u_cpu1)\/\S+/...\/${1}\/\*/ if( $endpoint_block !~ /\/\*/ ) ;
          $endpoint_block =~ s/^a9mp_top\/u_a9mp_pwrwrp_OLS\/u_a9mp_pwrwrp_ILS\/u_a9mp_wholewrp\/u_a9mp_testwrp\/u_a9mp_corewrp\/(u_CORTEXA9INTEGRATION\/u_falcon\/u_cpu2)\/\S+/...\/${1}\/\*/ if( $endpoint_block !~ /\/\*/ ) ;
          $endpoint_block =~ s/^a9mp_top\/u_a9mp_pwrwrp_OLS\/u_a9mp_pwrwrp_ILS\/u_a9mp_wholewrp\/u_a9mp_testwrp\/u_a9mp_corewrp\/(u_CORTEXA9INTEGRATION\/u_falcon\/u_cpu3)\/\S+/...\/${1}\/\*/ if( $endpoint_block !~ /\/\*/ ) ;
          $endpoint_block =~ s/^a9mp_top\/u_a9mp_pwrwrp_OLS\/u_a9mp_pwrwrp_ILS\/u_a9mp_wholewrp\/u_a9mp_testwrp\/u_a9mp_corewrp\/(u_CORTEXA9INTEGRATION\/u_falcon\/u_scu)\/\S+/...\/${1}\/\*/ if( $endpoint_block !~ /\/\*/ ) ;
          $endpoint_block =~ s/^a9mp_top\/u_a9mp_pwrwrp_OLS\/u_a9mp_pwrwrp_ILS\/u_a9mp_wholewrp\/u_a9mp_testwrp\/u_a9mp_corewrp\/(u_CORTEXA9INTEGRATION\/u_falcon\/u_clk_module)\/\S+/...\/${1}\/\*/ if( $endpoint_block !~ /\/\*/ ) ;
          $endpoint_block =~ s/^a9mp_top\/u_a9mp_pwrwrp_OLS\/u_a9mp_pwrwrp_ILS\/u_a9mp_wholewrp\/u_a9mp_testwrp\/u_a9mp_corewrp\/(u_CORTEXA9INTEGRATION\/u_falcon\/u_topmbmux)\/\S+/...\/${1}\/\*/ if( $endpoint_block !~ /\/\*/ ) ;
          $endpoint_block =~ s/^a9mp_top\/u_a9mp_pwrwrp_OLS\/u_a9mp_pwrwrp_ILS\/u_a9mp_wholewrp\/u_a9mp_testwrp\/u_a9mp_corewrp\/(u_CORTEXA9INTEGRATION\/u_falcon)\/\S+/...\/${1}\/\*/ if( $endpoint_block !~ /\/\*/ ) ;
          $endpoint_block =~ s/^a9mp_top\/u_a9mp_pwrwrp_OLS\/u_a9mp_pwrwrp_ILS\/u_a9mp_wholewrp\/u_a9mp_testwrp\/u_a9mp_corewrp\/([^\/]+)\/\S+/...\/${1}\/\*/ if( $endpoint_block !~ /\/\*/ ) ;
          $endpoint_block =~ s/^a9mp_top\/u_a9mp_pwrwrp_OLS\/u_a9mp_pwrwrp_ILS\/u_a9mp_wholewrp\/u_a9mp_testwrp\/([^\/]+)\/\S+/...\/${1}\/\*/ if( $endpoint_block !~ /\/\*/ ) ;
          $endpoint_block =~ s/^a9mp_top\/u_a9mp_pwrwrp_OLS\/u_a9mp_pwrwrp_ILS\/u_a9mp_wholewrp\/([^\/]+)\/\S+/...\/${1}\/\*/ if( $endpoint_block !~ /\/\*/ ) ;
          $endpoint_block =~ s/^a9mp_top\/u_a9mp_pwrwrp_OLS\/u_a9mp_pwrwrp_ILS\/([^\/]+)\/\S+/...\/${1}\/\*/ if( $endpoint_block !~ /\/\*/ ) ;
          $endpoint_block =~ s/^a9mp_top\/u_a9mp_pwrwrp_OLS\/([^\/]+)\/\S+/...\/${1}\/\*/ if( $endpoint_block !~ /\/\*/ ) ;
          $endpoint_block =~ s/^(a9mp_top\/[^\/]+)\/\S+/${1}\/\*/ if( $endpoint_block !~ /\/\*/ ) ;
          $endpoint_block =~ s/^([^\/]+)\/\S+/${1}\/\*/ if( $endpoint_block !~ /\/\*/ ) ;

         #$endpoint_block =~ s/\/.*$// if( $endpoint_block eq $endpoint_pin ) ;
        }
    ##### DEFAULT #####
    } else {
      if( $endpoint_pin !~ /\// ) {
        $endpoint_block = "out" ;
      } else {
        $endpoint_block = $endpoint_pin ;
        $endpoint_block =~ s/\/.*$// ;
      }
    }

    $block = "$startpoint_block,$endpoint_block" ;
    if( $worst_slack{$block} eq "" ) {
        $worst_slack{$block} = 999999 ;
    }
  }

  ########################################################################
  # count stage
  #
  if( $check_stage_count == 1 ) {
    if( $is_data_path == 1 ) {
      if( / \(net\) / ) {
       #$stage_count++ ;
        $stage_count++ if( $delay > 0.000 ) ;
      }
      if( /^\s*data arrival time / ) {
        $is_data_path = 0 ;
      }
    }
  }

# ########################################################################
# # check delay cells
# #
# if( $path_type eq "max" ) {
#   if( $design eq "cinnamon" ) {
#     if( /^\s+(\S+)\s+\(SU[NH]_DEL_R\d+_\d+\)\s+/ ) {
#       $delay_cell_found = 1 ;
#     }
#   }
# }
# 
  ########################################################################
  # get clock reconvergence pessimism
  #
  if( /^\s+clock reconvergence pessimism\s+(-*\d+\.*\d*)\s+/ ) {
    ( $crp ) =
      /^\s+clock reconvergence pessimism\s+(-*\d+\.*\d*)\s+/ ;
  }

  ########################################################################
  # check slack
  #
  if( /^\**\s*slack \((\S*).*\)/ ) {
    #( $slack ) = /slack \(\S+\)\s+(\S+)/ ;
    ( $slack ) = /slack \(\S+\).*\s+(\S+)\s*$/ ;

    $flag = 1 ;
    $flag = 0 if( $slack > 0.000 ) ;
    if( $flag == 1 ) {
      if( ( $path_slack{$startpoint,$endpoint} eq "" ) || ( $slack != $path_slack{$startpoint,$endpoint} ) ) {
  
        ##### check slack range #####
        if( $resolution eq "high" ) {
          if(      ( $slack <=  0.000 ) && ( $slack > -0.010 ) ) {
            $violation_count_per_range{"0000_0010"}++ ;
          } elsif( ( $slack <= -0.010 ) && ( $slack > -0.020 ) ) {
            $violation_count_per_range{"0010_0020"}++ ;
          } elsif( ( $slack <= -0.020 ) && ( $slack > -0.030 ) ) {
            $violation_count_per_range{"0020_0030"}++ ;
          } elsif( ( $slack <= -0.030 ) && ( $slack > -0.040 ) ) {
            $violation_count_per_range{"0030_0040"}++ ;
          } elsif( ( $slack <= -0.040 ) && ( $slack > -0.050 ) ) {
            $violation_count_per_range{"0040_0050"}++ ;
          } elsif( ( $slack <= -0.050 ) && ( $slack > -0.060 ) ) {
            $violation_count_per_range{"0050_0060"}++ ;
          } elsif( ( $slack <= -0.060 ) && ( $slack > -0.070 ) ) {
            $violation_count_per_range{"0060_0070"}++ ;
          } elsif( ( $slack <= -0.070 ) && ( $slack > -0.080 ) ) {
            $violation_count_per_range{"0070_0080"}++ ;
          } elsif( ( $slack <= -0.080 ) && ( $slack > -0.090 ) ) {
            $violation_count_per_range{"0080_0090"}++ ;
          } elsif( ( $slack <= -0.090 ) && ( $slack > -0.100 ) ) {
            $violation_count_per_range{"0090_0100"}++ ;
          } elsif( ( $slack <= -0.100 ) && ( $slack > -0.110 ) ) {
            $violation_count_per_range{"0100_0110"}++ ;
          } elsif( ( $slack <= -0.110 ) && ( $slack > -0.120 ) ) {
            $violation_count_per_range{"0110_0120"}++ ;
          } elsif( ( $slack <= -0.120 ) && ( $slack > -0.130 ) ) {
            $violation_count_per_range{"0120_0130"}++ ;
          } elsif( ( $slack <= -0.130 ) && ( $slack > -0.140 ) ) {
            $violation_count_per_range{"0130_0140"}++ ;
          } elsif( ( $slack <= -0.140 ) && ( $slack > -0.150 ) ) {
            $violation_count_per_range{"0140_0150"}++ ;
          } elsif( ( $slack <= -0.150 ) && ( $slack > -0.160 ) ) {
            $violation_count_per_range{"0150_0160"}++ ;
          } elsif( ( $slack <= -0.160 ) && ( $slack > -0.170 ) ) {
            $violation_count_per_range{"0160_0170"}++ ;
          } elsif( ( $slack <= -0.170 ) && ( $slack > -0.180 ) ) {
            $violation_count_per_range{"0170_0180"}++ ;
          } elsif( ( $slack <= -0.180 ) && ( $slack > -0.190 ) ) {
            $violation_count_per_range{"0180_0190"}++ ;
          } elsif( ( $slack <= -0.190 ) && ( $slack > -0.200 ) ) {
            $violation_count_per_range{"0190_0200"}++ ;
          } elsif( ( $slack <= -0.200 ) && ( $slack > -0.300 ) ) {
            $violation_count_per_range{"0200_0300"}++ ;
          } elsif( ( $slack <= -0.300 ) && ( $slack > -0.400 ) ) {
            $violation_count_per_range{"0300_0400"}++ ;
          } elsif( ( $slack <= -0.400 ) && ( $slack > -0.500 ) ) {
            $violation_count_per_range{"0400_0500"}++ ;
          } elsif( ( $slack <= -0.500 ) && ( $slack > -1.000 ) ) {
            $violation_count_per_range{"0500_1000"}++ ;
          } elsif( ( $slack <= -1.000 ) && ( $slack > -2.000 ) ) {
            $violation_count_per_range{"1000_2000"}++ ;
          } elsif( ( $slack <= -2.000 ) && ( $slack > -5.000 ) ) {
            $violation_count_per_range{"2000_5000"}++ ;
          } elsif( ( $slack <= -5.000 ) ) {
            $violation_count_per_range{"5000_"}++ ;
          }
        } else {
          if(      ( $slack <=  0.0 ) && ( $slack > -0.1 ) ) {
            $violation_count_per_range{"0000_0100"}++ ;
          } elsif( ( $slack <= -0.1 ) && ( $slack > -0.2 ) ) {
            $violation_count_per_range{"0100_0200"}++ ;
          } elsif( ( $slack <= -0.2 ) && ( $slack > -0.5 ) ) {
            $violation_count_per_range{"0200_0500"}++ ;
          } elsif( ( $slack <= -0.5 ) && ( $slack > -1.0 ) ) {
            $violation_count_per_range{"0500_1000"}++ ;
          } elsif( ( $slack <= -1.0 ) && ( $slack > -2.0 ) ) {
            $violation_count_per_range{"1000_2000"}++ ;
          } elsif( ( $slack <= -2.0 ) && ( $slack > -5.0 ) ) {
            $violation_count_per_range{"2000_5000"}++ ;
          } elsif( ( $slack <= -5.0 ) ) {
            $violation_count_per_range{"5000_"}++ ;
          }
        }
        if( $slack <= 0.000 ) {
          $violation_count_per_range{total}++ ;
        }
        if( $worst_slack{total} eq "" ) {
            $worst_slack{total} = $slack ;
        } elsif( $slack < $worst_slack{total} ) {
            $worst_slack{total} = $slack ;
        }
        $total_negative_slack{total} = $total_negative_slack{total} - $slack if( $slack <= 0.000 ) ;
  
        ##### check path group #####
        if( $check_path_group == 1 ) {
          if( $slack <= 0.000 ) {
            $violation_count_per_path_group{$path_group}++ ;
            $violation_count_per_path_group{total}++ ;
          }
          if(   $worst_slack_per_path_group{$path_group} > $slack ) {
                $worst_slack_per_path_group{$path_group} = $slack ;
            if( $worst_slack_per_path_group{total} > $slack ) {
                $worst_slack_per_path_group{total} = $slack ;
            }
          }
          $total_negative_slack_per_path_group{$path_group} = $total_negative_slack_per_path_group{$path_group} - $slack if( $slack <= 0.000 ) ;
        }
  
        ##### check clock group #####
        if( $check_clock_group == 1 ) {
          if( $slack <= 0.000 ) {
            $violation_count_per_clock_group{$clock_group}++ ;
            $violation_count_per_clock_group{total}++ ;
          }
          if(   $worst_slack_per_clock_group{$clock_group} > $slack ) {
                $worst_slack_per_clock_group{$clock_group} = $slack ;
            if( $worst_slack_per_clock_group{total} > $slack ) {
                $worst_slack_per_clock_group{total} = $slack ;
            }
          }
          $total_negative_slack_per_clock_group{$clock_group} = $total_negative_slack_per_clock_group{$clock_group} - $slack if( $slack <= 0.000 ) ;
        }
  
        ##### check block #####
        if( $check_block == 1 ) {
          if( $slack <= 0.000 ) {
            $violation_count_per_block{$block}++ ;
            $violation_count_per_block{total}++ ;
          }
          if(   $worst_slack_per_block{$block} > $slack ) {
                $worst_slack_per_block{$block} = $slack ;
            if( $worst_slack_per_block{total} > $slack ) {
                $worst_slack_per_block{total} = $slack ;
            }
          }
          $total_negative_slack_per_block{$block} = $total_negative_slack_per_block{$block} - $slack if( $slack <= 0.000 ) ;
        }
  
        ##### check stage count #####
        if( $check_stage_count == 1 ) {
          $path_stage_count{$startpoint,$endpoint} = $stage_count ;
          if( $endpoint_stage_count{$endpoint} eq "" ) {
            $endpoint_stage_count{$endpoint} = $stage_count ;
          } elsif( $stage_count > $endpoint_stage_count{$endpoint} )  {
            $endpoint_stage_count{$endpoint} = $stage_count ;
          }
          if( $startpoint_stage_count{$startpoint} eq "" ) {
            $startpoint_stage_count{$startpoint} = $stage_count ;
          } elsif( $stage_count > $startpoint_stage_count{$startpoint} ) {
            $startpoint_stage_count{$startpoint} = $stage_count ;
          }
          if( $slack <= 0.000 ) {
            $violation_count_per_stage_count{$stage_count}++ ;
            $violation_count_per_stage_count{total}++ ;
          }
        }
  
        ##### check skew range #####
        if( $check_clock_network_delay == 1 ) {
  
          ##### check derating skew range #####
  
          $derating_clock_network_delay{$startpoint} = $startpoint_derating_clock_network_delay ;
          $derating_clock_network_delay{$endpoint} = $endpoint_derating_clock_network_delay ;
  
          $derating_skew = $derating_clock_network_delay{$endpoint} - $derating_clock_network_delay{$startpoint} + $crp ;
          if( $slack <= 0.000 ) {
            if(                                    ( $derating_skew < -5.0 ) ) {
              $violation_count_per_derating_skew_range{"_N5000"}++ ;
            } elsif( ( $derating_skew >= -5.0 ) && ( $derating_skew < -2.0 ) ) {
              $violation_count_per_derating_skew_range{"N5000_N2000"}++ ;
            } elsif( ( $derating_skew >= -2.0 ) && ( $derating_skew < -1.0 ) ) {
              $violation_count_per_derating_skew_range{"N2000_N1000"}++ ;
            } elsif( ( $derating_skew >= -1.0 ) && ( $derating_skew < -0.9 ) ) {
              $violation_count_per_derating_skew_range{"N1000_N0900"}++ ;
            } elsif( ( $derating_skew >= -0.9 ) && ( $derating_skew < -0.8 ) ) {
              $violation_count_per_derating_skew_range{"N0900_N0800"}++ ;
            } elsif( ( $derating_skew >= -0.8 ) && ( $derating_skew < -0.7 ) ) {
              $violation_count_per_derating_skew_range{"N0800_N0700"}++ ;
            } elsif( ( $derating_skew >= -0.7 ) && ( $derating_skew < -0.6 ) ) {
              $violation_count_per_derating_skew_range{"N0700_N0600"}++ ;
            } elsif( ( $derating_skew >= -0.6 ) && ( $derating_skew < -0.5 ) ) {
              $violation_count_per_derating_skew_range{"N0600_N0500"}++ ;
            } elsif( ( $derating_skew >= -0.5 ) && ( $derating_skew < -0.4 ) ) {
              $violation_count_per_derating_skew_range{"N0500_N0400"}++ ;
            } elsif( ( $derating_skew >= -0.4 ) && ( $derating_skew < -0.3 ) ) {
              $violation_count_per_derating_skew_range{"N0400_N0300"}++ ;
            } elsif( ( $derating_skew >= -0.3 ) && ( $derating_skew < -0.2 ) ) {
              $violation_count_per_derating_skew_range{"N0300_N0200"}++ ;
            } elsif( ( $derating_skew >= -0.2 ) && ( $derating_skew < -0.1 ) ) {
              $violation_count_per_derating_skew_range{"N0200_N0100"}++ ;
            } elsif( ( $derating_skew >= -0.1 ) && ( $derating_skew <  0.0 ) ) {
              $violation_count_per_derating_skew_range{"N0100_N0000"}++ ;
            } elsif( ( $derating_skew >=  0.0 ) && ( $derating_skew <  0.1 ) ) {
              $violation_count_per_derating_skew_range{"P0000_P0100"}++ ;
            } elsif( ( $derating_skew >=  0.1 ) && ( $derating_skew <  0.2 ) ) {
              $violation_count_per_derating_skew_range{"P0100_P0200"}++ ;
            } elsif( ( $derating_skew >=  0.2 ) && ( $derating_skew <  0.3 ) ) {
              $violation_count_per_derating_skew_range{"P0200_P0300"}++ ;
            } elsif( ( $derating_skew >=  0.3 ) && ( $derating_skew <  0.4 ) ) {
              $violation_count_per_derating_skew_range{"P0300_P0400"}++ ;
            } elsif( ( $derating_skew >=  0.4 ) && ( $derating_skew <  0.5 ) ) {
              $violation_count_per_derating_skew_range{"P0400_P0500"}++ ;
            } elsif( ( $derating_skew >=  0.5 ) && ( $derating_skew <  0.6 ) ) {
              $violation_count_per_derating_skew_range{"P0500_P0600"}++ ;
            } elsif( ( $derating_skew >=  0.6 ) && ( $derating_skew <  0.7 ) ) {
              $violation_count_per_derating_skew_range{"P0600_P0700"}++ ;
            } elsif( ( $derating_skew >=  0.7 ) && ( $derating_skew <  0.8 ) ) {
              $violation_count_per_derating_skew_range{"P0700_P0800"}++ ;
            } elsif( ( $derating_skew >=  0.8 ) && ( $derating_skew <  0.9 ) ) {
              $violation_count_per_derating_skew_range{"P0800_P0900"}++ ;
            } elsif( ( $derating_skew >=  0.9 ) && ( $derating_skew <  1.0 ) ) {
              $violation_count_per_derating_skew_range{"P0900_P1000"}++ ;
            } elsif( ( $derating_skew >=  1.0 ) && ( $derating_skew <  2.0 ) ) {
              $violation_count_per_derating_skew_range{"P1000_P2000"}++ ;
            } elsif( ( $derating_skew >=  2.0 ) && ( $derating_skew <  5.0 ) ) {
              $violation_count_per_derating_skew_range{"P2000_P5000"}++ ;
            } elsif( ( $derating_skew >=  5.0 ) ) {
              $violation_count_per_derating_skew_range{"P5000_"}++ ;
            }
  
            $violation_count_per_derating_skew_range{total}++ ;
          }
  
#         ##### check original skew range #####
# 
#         if( $path_type eq "min" ) {
#           $original_clock_network_delay{$startpoint} = $derating_clock_network_delay{$startpoint} / $min_clock_paths_derating_factor ;
#         } else {
#           $original_clock_network_delay{$startpoint} = $derating_clock_network_delay{$startpoint} / $max_clock_paths_derating_factor ;
#         }
#         if( $path_type eq "min" ) {
#           $original_clock_network_delay{$endpoint} = $derating_clock_network_delay{$endpoint} / $max_clock_paths_derating_factor ;
#         } else {
#           $original_clock_network_delay{$endpoint} = $derating_clock_network_delay{$endpoint} / $min_clock_paths_derating_factor ;
#         }
# 
#         $original_skew = $original_clock_network_delay{$endpoint} - $original_clock_network_delay{$startpoint} ;
#         if( $slack <= 0.000 ) {
#           if(                                    ( $original_skew < -5.0 ) ) {
#             $violation_count_per_original_skew_range{"_N5000"}++ ;
#           } elsif( ( $original_skew >= -5.0 ) && ( $original_skew < -2.0 ) ) {
#             $violation_count_per_original_skew_range{"N5000_N2000"}++ ;
#           } elsif( ( $original_skew >= -2.0 ) && ( $original_skew < -1.0 ) ) {
#             $violation_count_per_original_skew_range{"N2000_N1000"}++ ;
#           } elsif( ( $original_skew >= -1.0 ) && ( $original_skew < -0.9 ) ) {
#             $violation_count_per_original_skew_range{"N1000_N0900"}++ ;
#           } elsif( ( $original_skew >= -0.9 ) && ( $original_skew < -0.8 ) ) {
#             $violation_count_per_original_skew_range{"N0900_N0800"}++ ;
#           } elsif( ( $original_skew >= -0.8 ) && ( $original_skew < -0.7 ) ) {
#             $violation_count_per_original_skew_range{"N0800_N0700"}++ ;
#           } elsif( ( $original_skew >= -0.7 ) && ( $original_skew < -0.6 ) ) {
#             $violation_count_per_original_skew_range{"N0700_N0600"}++ ;
#           } elsif( ( $original_skew >= -0.6 ) && ( $original_skew < -0.5 ) ) {
#             $violation_count_per_original_skew_range{"N0600_N0500"}++ ;
#           } elsif( ( $original_skew >= -0.5 ) && ( $original_skew < -0.4 ) ) {
#             $violation_count_per_original_skew_range{"N0500_N0400"}++ ;
#           } elsif( ( $original_skew >= -0.4 ) && ( $original_skew < -0.3 ) ) {
#             $violation_count_per_original_skew_range{"N0400_N0300"}++ ;
#           } elsif( ( $original_skew >= -0.3 ) && ( $original_skew < -0.2 ) ) {
#             $violation_count_per_original_skew_range{"N0300_N0200"}++ ;
#           } elsif( ( $original_skew >= -0.2 ) && ( $original_skew < -0.1 ) ) {
#             $violation_count_per_original_skew_range{"N0200_N0100"}++ ;
#           } elsif( ( $original_skew >= -0.1 ) && ( $original_skew <  0.0 ) ) {
#             $violation_count_per_original_skew_range{"N0100_N0000"}++ ;
#           } elsif( ( $original_skew >=  0.0 ) && ( $original_skew <  0.1 ) ) {
#             $violation_count_per_original_skew_range{"P0000_P0100"}++ ;
#           } elsif( ( $original_skew >=  0.1 ) && ( $original_skew <  0.2 ) ) {
#             $violation_count_per_original_skew_range{"P0100_P0200"}++ ;
#           } elsif( ( $original_skew >=  0.2 ) && ( $original_skew <  0.3 ) ) {
#             $violation_count_per_original_skew_range{"P0200_P0300"}++ ;
#           } elsif( ( $original_skew >=  0.3 ) && ( $original_skew <  0.4 ) ) {
#             $violation_count_per_original_skew_range{"P0300_P0400"}++ ;
#           } elsif( ( $original_skew >=  0.4 ) && ( $original_skew <  0.5 ) ) {
#             $violation_count_per_original_skew_range{"P0400_P0500"}++ ;
#           } elsif( ( $original_skew >=  0.5 ) && ( $original_skew <  0.6 ) ) {
#             $violation_count_per_original_skew_range{"P0500_P0600"}++ ;
#           } elsif( ( $original_skew >=  0.6 ) && ( $original_skew <  0.7 ) ) {
#             $violation_count_per_original_skew_range{"P0600_P0700"}++ ;
#           } elsif( ( $original_skew >=  0.7 ) && ( $original_skew <  0.8 ) ) {
#             $violation_count_per_original_skew_range{"P0700_P0800"}++ ;
#           } elsif( ( $original_skew >=  0.8 ) && ( $original_skew <  0.9 ) ) {
#             $violation_count_per_original_skew_range{"P0800_P0900"}++ ;
#           } elsif( ( $original_skew >=  0.9 ) && ( $original_skew <  1.0 ) ) {
#             $violation_count_per_original_skew_range{"P0900_P1000"}++ ;
#           } elsif( ( $original_skew >=  1.0 ) && ( $original_skew <  2.0 ) ) {
#             $violation_count_per_original_skew_range{"P1000_P2000"}++ ;
#           } elsif( ( $original_skew >=  2.0 ) && ( $original_skew <  5.0 ) ) {
#             $violation_count_per_original_skew_range{"P2000_P5000"}++ ;
#           } elsif( ( $original_skew >=  5.0 ) ) {
#             $violation_count_per_original_skew_range{"P5000_"}++ ;
#           }
# 
#           $violation_count_per_original_skew_range{total}++ ;
#         }
        }
  
        ##### check endpoints #####
  #     $clock{$startpoint} = $startpoint_clock ;
        $clock_root_arrival{"$startpoint_pin:$startpoint_clock"} = $startpoint_clock_root_arrival ;
  #     $clock{$endpoint} = $endpoint_clock ;
        $clock_root_arrival{"$endpoint_pin:$endpoint_clock"} = $endpoint_clock_root_arrival ;
  
        ##### check endpoints #####
       #$endpoints_per_startpoint{"$startpoint_pin:$startpoint_clock"} = $endpoints_per_startpoint{"$startpoint_pin:$startpoint_clock"} . " " . "$endpoint_pin:$endpoint_clock" ;
        $endpoints_per_startpoint{$startpoint} = $endpoints_per_startpoint{$startpoint} . " " . $endpoint ;
        $path_slack{$startpoint,$endpoint} = $slack ;
        if( $startpoint_worst_slack{$startpoint} eq "" ) {
          $startpoint_worst_slack{$startpoint} = $slack ;
        } elsif( $slack < $startpoint_worst_slack{$startpoint} ) {
          $startpoint_worst_slack{$startpoint} = $slack ;
        }
        $path_crp{$startpoint,$endpoint} = $crp ;
  
#       ##### check delay cell #####
#       if( $path_type eq "max" ) {
#         if( $delay_cell_found == 1 ) {
#           $delay_cell_exist{$startpoint,$endpoint} = 1 ;
#         }
#       }
  
      }
    }
  }
}

########################################################################
# check if timing report is correct
#
#if( $is_report_timing != 1 ) {
#  die( "Error: incomplete timing report.\n" ) ;
#}

########################################################################
# print violations per range
#
if( $resolution eq "high" ) {
printf( "\n" ) ;
printf( " %-30s  %20s\n", "violation range", "# of violations" ) ;
printf( " %-30s  %20s\n", "------------------------------", "--------------------" ) ;
printf( " %-30s  %20d\n", "-0.000ns < -0.010ns", $violation_count_per_range{"0000_0010"} ) ;
printf( " %-30s  %20d\n", "-0.010ns < -0.020ns", $violation_count_per_range{"0010_0020"} ) ;
printf( " %-30s  %20d\n", "-0.020ns < -0.030ns", $violation_count_per_range{"0020_0030"} ) ;
printf( " %-30s  %20d\n", "-0.030ns < -0.040ns", $violation_count_per_range{"0030_0040"} ) ;
printf( " %-30s  %20d\n", "-0.040ns < -0.050ns", $violation_count_per_range{"0040_0050"} ) ;
printf( " %-30s  %20d\n", "-0.050ns < -0.060ns", $violation_count_per_range{"0050_0060"} ) ;
printf( " %-30s  %20d\n", "-0.060ns < -0.070ns", $violation_count_per_range{"0060_0070"} ) ;
printf( " %-30s  %20d\n", "-0.070ns < -0.080ns", $violation_count_per_range{"0070_0080"} ) ;
printf( " %-30s  %20d\n", "-0.080ns < -0.090ns", $violation_count_per_range{"0080_0090"} ) ;
printf( " %-30s  %20d\n", "-0.090ns < -0.100ns", $violation_count_per_range{"0090_0100"} ) ;
printf( " %-30s  %20d\n", "-0.100ns < -0.110ns", $violation_count_per_range{"0100_0110"} ) ;
printf( " %-30s  %20d\n", "-0.110ns < -0.120ns", $violation_count_per_range{"0110_0120"} ) ;
printf( " %-30s  %20d\n", "-0.120ns < -0.130ns", $violation_count_per_range{"0120_0130"} ) ;
printf( " %-30s  %20d\n", "-0.130ns < -0.140ns", $violation_count_per_range{"0130_0140"} ) ;
printf( " %-30s  %20d\n", "-0.140ns < -0.150ns", $violation_count_per_range{"0140_0150"} ) ;
printf( " %-30s  %20d\n", "-0.150ns < -0.160ns", $violation_count_per_range{"0150_0160"} ) ;
printf( " %-30s  %20d\n", "-0.160ns < -0.170ns", $violation_count_per_range{"0160_0170"} ) ;
printf( " %-30s  %20d\n", "-0.170ns < -0.180ns", $violation_count_per_range{"0170_0180"} ) ;
printf( " %-30s  %20d\n", "-0.180ns < -0.190ns", $violation_count_per_range{"0180_0190"} ) ;
printf( " %-30s  %20d\n", "-0.190ns < -0.200ns", $violation_count_per_range{"0190_0200"} ) ;
printf( " %-30s  %20d\n", "-0.200ns < -0.300ns", $violation_count_per_range{"0200_0300"} ) ;
printf( " %-30s  %20d\n", "-0.300ns < -0.400ns", $violation_count_per_range{"0300_0400"} ) ;
printf( " %-30s  %20d\n", "-0.400ns < -0.500ns", $violation_count_per_range{"0400_0500"} ) ;
printf( " %-30s  %20d\n", "-0.500ns < -1.000ns", $violation_count_per_range{"0500_1000"} ) ;
printf( " %-30s  %20d\n", "-1.000ns < -2.000ns", $violation_count_per_range{"1000_2000"} ) ;
printf( " %-30s  %20d\n", "-2.000ns < -5.000ns", $violation_count_per_range{"2000_5000"} ) ;
printf( " %-30s  %20d\n", "-5.000ns <         ", $violation_count_per_range{"5000_"} ) ;
printf( " %-30s  %20s\n", "------------------------------", "--------------------" ) ;
printf( " %-30s  %20d\n", "total              ", $violation_count_per_range{total} ) ;
} else {
printf( "\n" ) ;
printf( " %-30s  %20s\n", "violation range", "# of violations" ) ;
printf( " %-30s  %20s\n", "------------------------------", "--------------------" ) ;
printf( " %-30s  %20d\n", "-0.0ns < -0.1ns", $violation_count_per_range{"0000_0100"} ) ;
printf( " %-30s  %20d\n", "-0.1ns < -0.2ns", $violation_count_per_range{"0100_0200"} ) ;
printf( " %-30s  %20d\n", "-0.2ns < -0.5ns", $violation_count_per_range{"0200_0500"} ) ;
printf( " %-30s  %20d\n", "-0.5ns < -1.0ns", $violation_count_per_range{"0500_1000"} ) ;
printf( " %-30s  %20d\n", "-1.0ns < -2.0ns", $violation_count_per_range{"1000_2000"} ) ;
printf( " %-30s  %20d\n", "-2.0ns < -5.0ns", $violation_count_per_range{"2000_5000"} ) ;
printf( " %-30s  %20d\n", "-5.0ns <       ", $violation_count_per_range{"5000_"} ) ;
printf( " %-30s  %20s\n", "------------------------------", "--------------------" ) ;
printf( " %-30s  %20d\n", "total          ", $violation_count_per_range{total} ) ;
}
#if( $violation_count_per_range{total} == 0 ) {
#  exit ;
#}

########################################################################
# print violations per block
#
if( $check_block == 1 ) {
  printf( "\n" ) ;
  printf( " %-50s  %-50s  %20s  %20s  %20s\n", "startpoint block", "endpoint block", "# of violations", "worst slack", "total negative slack" ) ;
  printf( " %-50s  %-50s  %20s  %20s  %20s\n", "--------------------------------------------------", "--------------------------------------------------", "--------------------", "--------------------", "--------------------" ) ;
  foreach $block ( sort( { $total_negative_slack_per_block{$b} <=> $total_negative_slack_per_block{$a} } keys( %total_negative_slack_per_block ) ) ) {
    if( $worst_slack_per_block{$block} <= 0.000 ) {
      if( $block ne "total" ) {
        $_ = $block ;
        split( ",", $_ ) ;
        $startpoint_block = $_[0] ;
        $endpoint_block = $_[1] ;
        printf( " %-50s  %-50s  %20d  %20.3f  %20.3f\n", $startpoint_block, $endpoint_block, $violation_count_per_block{$block}, $worst_slack_per_block{$block}, $total_negative_slack_per_block{$block} ) ;
      }
    }
  }
  printf( " %-50s  %-50s  %20s  %20s  %20s\n", "--------------------------------------------------", "--------------------------------------------------", "--------------------", "--------------------", "--------------------" ) ;
  printf( " %-50s  %-50s  %20d  %20.3f  %20.3f\n", "*", "*", $violation_count_per_block{total}, $worst_slack_per_block{total}, $total_negative_slack{total} ) ;
}

########################################################################
# print violations per path group
#
if( $check_path_group == 1 ) {
  printf( "\n" ) ;
  printf( " %-30s  %20s  %20s  %20s\n", "path group", "# of violations", "worst slack", "total negative slack" ) ;
  printf( " %-30s  %20s  %20s  %20s\n", "------------------------------", "--------------------", "--------------------", "--------------------" ) ;
  foreach $path_group ( sort( { $total_negative_slack_per_path_group{$b} <=> $total_negative_slack_per_path_group{$b} } keys( %total_negative_slack_per_path_group ) ) ) {
    if( $worst_slack_per_path_group{$path_group} <= 0.000 ) {
      if( $path_group ne "total" ) {
        printf( " %-30s  %20s  %20.3f  %20.3f\n", $path_group, $violation_count_per_path_group{$path_group}, $worst_slack_per_path_group{$path_group}, $total_negative_slack_per_path_group{$path_group} ) ;
      }
    }
  }
  printf( " %-30s  %20s  %20s  %20s\n", "------------------------------", "--------------------", "--------------------", "--------------------" ) ;
  printf( " %-30s  %20s  %20.3f  %20.3f\n", "*", $violation_count_per_path_group{total}, $worst_slack_per_path_group{total}, $total_negative_slack{total} ) ;
}

########################################################################
# print violations per clock group
#
if( $check_clock_group == 1 ) {
  printf( "\n" ) ;
  printf( " %-50s  %-50s  %20s  %20s  %20s\n", "startpoint clock", "endpoint clock", "# of violations", "worst slack", "total negative slack" ) ;
  printf( " %-50s  %-50s  %20s  %20s  %20s\n", "--------------------------------------------------", "--------------------------------------------------", "--------------------", "--------------------", "--------------------" ) ;
  foreach $clock_group ( sort( { $total_negative_slack_per_clock_group{$b} <=> $total_negative_slack_per_clock_group{$a} } keys( %total_negative_slack_per_clock_group ) ) ) {
    if( $worst_slack_per_clock_group{$clock_group} <= 0.000 ) {
      if( $clock_group ne "total" ) {
        $_ = $clock_group ;
        split( ",", $_ ) ;
        $startpoint_clock = $_[0] ;
        $endpoint_clock = $_[1] ;
        printf( " %-50s  %-50s  %20s  %20.3f  %20.3f\n", $startpoint_clock, $endpoint_clock, $violation_count_per_clock_group{$clock_group}, $worst_slack_per_clock_group{$clock_group}, $total_negative_slack_per_clock_group{$clock_group} ) ;
      }
    }
  }
  printf( " %-50s  %-50s  %20s  %20s  %20s\n", "--------------------------------------------------", "--------------------------------------------------", "--------------------", "--------------------", "--------------------" ) ;
  printf( " %-50s  %-50s  %20s  %20.3f  %20.3f\n", "*", "*", $violation_count_per_clock_group{total}, $worst_slack_per_clock_group{total}, $total_negative_slack{total} ) ;
}

########################################################################
# print violations per derating skew range
#
if( $check_clock_network_delay == 1 ) {
#if( $is_timing_derate == 1 ) {
printf( "\n" ) ;
printf( " %-30s  %20s\n", "derating skew range", "# of violations" ) ;
printf( " %-30s  %20s\n", "------------------------------", "--------------------" ) ;
printf( " %-30s  %20d\n", "       < -5.0ns", $violation_count_per_derating_skew_range{"_N5000"} ) ;
printf( " %-30s  %20d\n", "-5.0ns < -2.0ns", $violation_count_per_derating_skew_range{"N5000_N2000"} ) ;
printf( " %-30s  %20d\n", "-2.0ns < -1.0ns", $violation_count_per_derating_skew_range{"N2000_N1000"} ) ;
printf( " %-30s  %20d\n", "-1.0ns < -0.9ns", $violation_count_per_derating_skew_range{"N1000_N0900"} ) ;
printf( " %-30s  %20d\n", "-0.9ns < -0.8ns", $violation_count_per_derating_skew_range{"N0900_N0800"} ) ;
printf( " %-30s  %20d\n", "-0.8ns < -0.7ns", $violation_count_per_derating_skew_range{"N0800_N0700"} ) ;
printf( " %-30s  %20d\n", "-0.7ns < -0.6ns", $violation_count_per_derating_skew_range{"N0700_N0600"} ) ;
printf( " %-30s  %20d\n", "-0.6ns < -0.5ns", $violation_count_per_derating_skew_range{"N0600_N0500"} ) ;
printf( " %-30s  %20d\n", "-0.5ns < -0.4ns", $violation_count_per_derating_skew_range{"N0500_N0400"} ) ;
printf( " %-30s  %20d\n", "-0.4ns < -0.3ns", $violation_count_per_derating_skew_range{"N0400_N0300"} ) ;
printf( " %-30s  %20d\n", "-0.3ns < -0.2ns", $violation_count_per_derating_skew_range{"N0300_N0200"} ) ;
printf( " %-30s  %20d\n", "-0.2ns < -0.1ns", $violation_count_per_derating_skew_range{"N0200_N0100"} ) ;
printf( " %-30s  %20d\n", "-0.1ns <  0.0ns", $violation_count_per_derating_skew_range{"N0100_N0000"} ) ;
printf( " %-30s  %20d\n", " 0.0ns < +0.1ns", $violation_count_per_derating_skew_range{"P0000_P0100"} ) ;
printf( " %-30s  %20d\n", "+0.1ns < +0.2ns", $violation_count_per_derating_skew_range{"P0100_P0200"} ) ;
printf( " %-30s  %20d\n", "+0.2ns < +0.3ns", $violation_count_per_derating_skew_range{"P0200_P0300"} ) ;
printf( " %-30s  %20d\n", "+0.3ns < +0.4ns", $violation_count_per_derating_skew_range{"P0300_P0400"} ) ;
printf( " %-30s  %20d\n", "+0.4ns < +0.5ns", $violation_count_per_derating_skew_range{"P0400_P0500"} ) ;
printf( " %-30s  %20d\n", "+0.5ns < +0.6ns", $violation_count_per_derating_skew_range{"P0500_P0600"} ) ;
printf( " %-30s  %20d\n", "+0.6ns < +0.7ns", $violation_count_per_derating_skew_range{"P0600_P0700"} ) ;
printf( " %-30s  %20d\n", "+0.7ns < +0.8ns", $violation_count_per_derating_skew_range{"P0700_P0800"} ) ;
printf( " %-30s  %20d\n", "+0.8ns < +0.9ns", $violation_count_per_derating_skew_range{"P0800_P0900"} ) ;
printf( " %-30s  %20d\n", "+0.9ns < +1.0ns", $violation_count_per_derating_skew_range{"P0900_P1000"} ) ;
printf( " %-30s  %20d\n", "+1.0ns < +2.0ns", $violation_count_per_derating_skew_range{"P1000_P2000"} ) ;
printf( " %-30s  %20d\n", "+2.0ns < +5.0ns", $violation_count_per_derating_skew_range{"P2000_P5000"} ) ;
printf( " %-30s  %20d\n", "+5.0ns <       ", $violation_count_per_derating_skew_range{"P5000_"} ) ;
printf( " %-30s  %20s\n", "------------------------------", "--------------------" ) ;
printf( " %-30s  %20d\n", "total          ", $violation_count_per_derating_skew_range{total} ) ;
#}

#printf( "\n" ) ;
#printf( " %-30s  %20s\n", "original skew range", "# of violations" ) ;
#printf( " %-30s  %20s\n", "------------------------------", "--------------------" ) ;
#printf( " %-30s  %20d\n", "       < -5.0ns", $violation_count_per_original_skew_range{"_N5000"} ) ;
#printf( " %-30s  %20d\n", "-5.0ns < -2.0ns", $violation_count_per_original_skew_range{"N5000_N2000"} ) ;
#printf( " %-30s  %20d\n", "-2.0ns < -1.0ns", $violation_count_per_original_skew_range{"N2000_N1000"} ) ;
#printf( " %-30s  %20d\n", "-1.0ns < -0.9ns", $violation_count_per_original_skew_range{"N1000_N0900"} ) ;
#printf( " %-30s  %20d\n", "-0.9ns < -0.8ns", $violation_count_per_original_skew_range{"N0900_N0800"} ) ;
#printf( " %-30s  %20d\n", "-0.8ns < -0.7ns", $violation_count_per_original_skew_range{"N0800_N0700"} ) ;
#printf( " %-30s  %20d\n", "-0.7ns < -0.6ns", $violation_count_per_original_skew_range{"N0700_N0600"} ) ;
#printf( " %-30s  %20d\n", "-0.6ns < -0.5ns", $violation_count_per_original_skew_range{"N0600_N0500"} ) ;
#printf( " %-30s  %20d\n", "-0.5ns < -0.4ns", $violation_count_per_original_skew_range{"N0500_N0400"} ) ;
#printf( " %-30s  %20d\n", "-0.4ns < -0.3ns", $violation_count_per_original_skew_range{"N0400_N0300"} ) ;
#printf( " %-30s  %20d\n", "-0.3ns < -0.2ns", $violation_count_per_original_skew_range{"N0300_N0200"} ) ;
#printf( " %-30s  %20d\n", "-0.2ns < -0.1ns", $violation_count_per_original_skew_range{"N0200_N0100"} ) ;
#printf( " %-30s  %20d\n", "-0.1ns <  0.0ns", $violation_count_per_original_skew_range{"N0100_N0000"} ) ;
#printf( " %-30s  %20d\n", " 0.0ns < +0.1ns", $violation_count_per_original_skew_range{"P0000_P0100"} ) ;
#printf( " %-30s  %20d\n", "+0.1ns < +0.2ns", $violation_count_per_original_skew_range{"P0100_P0200"} ) ;
#printf( " %-30s  %20d\n", "+0.2ns < +0.3ns", $violation_count_per_original_skew_range{"P0200_P0300"} ) ;
#printf( " %-30s  %20d\n", "+0.3ns < +0.4ns", $violation_count_per_original_skew_range{"P0300_P0400"} ) ;
#printf( " %-30s  %20d\n", "+0.4ns < +0.5ns", $violation_count_per_original_skew_range{"P0400_P0500"} ) ;
#printf( " %-30s  %20d\n", "+0.5ns < +0.6ns", $violation_count_per_original_skew_range{"P0500_P0600"} ) ;
#printf( " %-30s  %20d\n", "+0.6ns < +0.7ns", $violation_count_per_original_skew_range{"P0600_P0700"} ) ;
#printf( " %-30s  %20d\n", "+0.7ns < +0.8ns", $violation_count_per_original_skew_range{"P0700_P0800"} ) ;
#printf( " %-30s  %20d\n", "+0.8ns < +0.9ns", $violation_count_per_original_skew_range{"P0800_P0900"} ) ;
#printf( " %-30s  %20d\n", "+0.9ns < +1.0ns", $violation_count_per_original_skew_range{"P0900_P1000"} ) ;
#printf( " %-30s  %20d\n", "+1.0ns < +2.0ns", $violation_count_per_original_skew_range{"P1000_P2000"} ) ;
#printf( " %-30s  %20d\n", "+2.0ns < +5.0ns", $violation_count_per_original_skew_range{"P2000_P5000"} ) ;
#printf( " %-30s  %20d\n", "+5.0ns <       ", $violation_count_per_original_skew_range{"P5000_"} ) ;
#printf( " %-30s  %20s\n", "------------------------------", "--------------------" ) ;
#printf( " %-30s  %20d\n", "total          ", $violation_count_per_original_skew_range{total} ) ;
}

########################################################################
# print violations per stage count
#
if( $check_stage_count == 1 ) {
  printf( "\n" ) ;
  printf( " %-30s  %20s\n", "stage count", "# of violations" ) ;
  printf( " %-30s  %20s\n", "------------------------------", "--------------------" ) ;
  foreach $stage_count ( sort { $a <=> $b } keys( %violation_count_per_stage_count ) ) {
    if( $stage_count ne "total" ) {
      printf( " %30d  %20d\n", $stage_count, $violation_count_per_stage_count{$stage_count} ) ;
    }
  }
  printf( " %-30s  %20s\n", "------------------------------", "--------------------" ) ;
  printf( " %-30s  %20d\n", "total          ", $violation_count_per_stage_count{total} ) ;
}

########################################################################
# print endpoints per startpoint
#
printf( "\n" ) ;
printf( "<# of violations>\t<startpoint> <slack> (<stage_count>) (<clock>:<clock_network_delay>)\n" ) ;
printf( "\t\t\t<endpoint>   <slack> (<stage_count>) (<clock>:<clock_network_delay>) (<skew>)\n" ) ;
printf( "\n" ) ;
foreach $startpoint ( keys %endpoints_per_startpoint ) {
  @startpoint = split( /:/, $startpoint ) ;
  $startpoint_pin = @startpoint[0] ;
  $startpoint_clock = @startpoint[1] ;
  @endpoints = split( " ", $endpoints_per_startpoint{$startpoint} ) ;
  printf( "%d\t%s %.3f", $#endpoints + 1, $startpoint_pin, $startpoint_worst_slack{$startpoint} ) ;
  if( $check_stage_count == 1 ) {
    printf( " (%d)", $startpoint_stage_count{$startpoint} ) ;
  }
  if( $check_clock_network_delay == 1 ) {
   #if( $is_timing_derate == 1 ) {
   #  printf( " (%s:%.3f->%.3f)",
   #    $startpoint_clock, $original_clock_network_delay{$startpoint}, $derating_clock_network_delay{$startpoint} ) ;
   #} else {
   #  printf( " (%s:%.3f)",
   #    $startpoint_clock, $original_clock_network_delay{$startpoint} ) ;
   #}
    printf( " (%s:%.3f)",
      $startpoint_clock, $derating_clock_network_delay{$startpoint} ) ;
  }
  printf( "\n" ) ;

  foreach $endpoint ( @endpoints ) {
    @endpoint = split( /:/, $endpoint ) ;
    $endpoint_pin = @endpoint[0] ;
    $endpoint_clock = @endpoint[1] ;
    printf( "\t%s %.3f", $endpoint_pin, $path_slack{$startpoint,$endpoint} ) ;
    if( $check_stage_count == 1 ) {
      printf( " (%d)", $path_stage_count{$startpoint,$endpoint} ) ;
    }
    if( $check_clock_network_delay == 1 ) {
     #if( $is_timing_derate == 1 ) {
     #  printf( " (%s:%.3f->%.3f)",
     #    $endpoint_clock, $original_clock_network_delay{$endpoint}, $derating_clock_network_delay{$endpoint} ) ;
     #  printf( " (%.3f->%.3f)",
     #    $original_clock_network_delay{$endpoint} - $original_clock_network_delay{$startpoint},
     #    $derating_clock_network_delay{$endpoint} - $derating_clock_network_delay{$startpoint} ) ;
     #} else {
     #  printf( " (%s:%.3f)",
     #    $endpoint_clock, $original_clock_network_delay{$endpoint} ) ;
     #  printf( " (%.3f)",
     #    $original_clock_network_delay{$endpoint} - $original_clock_network_delay{$startpoint} ) ;
     #}
      printf( " (%s:%.3f)",
        $endpoint_clock, $derating_clock_network_delay{$endpoint} ) ;
      printf( " (%.3f)",
        $derating_clock_network_delay{$endpoint} - $derating_clock_network_delay{$startpoint} ) ;
      printf( " (%.3f)",
        $derating_clock_network_delay{$endpoint} - $derating_clock_network_delay{$startpoint} + $path_crp{$startpoint,$endpoint} ) ;
    }
    printf( "\n" ) ;

    ##### WARNING #####
    if( $path_type eq "max" ) {
      if( $delay_cell_exist{$startpoint,$endpoint} == 1 ) {
        printf( "Warning: delay cell(s) exist on path.\n" ) ;
      }
    }
  }
  printf( "\n" ) ;
}

