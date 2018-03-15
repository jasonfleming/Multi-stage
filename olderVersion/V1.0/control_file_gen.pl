#!/usr/bin/env perl
#
# version 1: Parent mesh simulation writes global surface elevation (63).
# It is used by bcGen.x for extracting BCs
# bcGen.x creates BC by reading external Boundary_Node file. This file
# contains node numbers of the parent mesh at locations of the open boundaries
# of the child mesh. bcGen.x reads fort.63 to extract BCs at the locations
# specified by Boundary_Node file.
#---------------------------------------------------------------------------------
# control_file_gen.pl
# ASGS program modified for use in the Multi-stage tool,
# 
# usage:
#   %perl control_file_gen.pl [--cst csdate] [--hst hstime]
#   [--dt timestep] [--nowcast] [--controltemplate templatefile] < storm1_fort.22
#
# --------------------------------------------------------------------------------
# Copyright(C) 2018 Florida Institute of Technology
# Copyright(C) 2018 Peyman Taeb & Robert J Weaver
#
# This program is prepared as a part of the Multi-stage tool.
# The Multi-stage tool is an open-source software providing the copyright
# holders the rights to run, study, change, and distribute the software under
# the terms and conditions of the third version of the GNU General Public
# License (GPLv3) as published in 2007.
# 
# Although careful considerations are given to the development of the
# Multi-stage tool with the aim of usefulness and helpfulness, we do not
# make any warranty express or implied, do not assume any responsibility for
# the accuracy, completeness, or usefulness of any components and outcomes.
#
# The terms and conditions of the GPL are available to anybody receiving a
# copy of the Multi-stage tool. It can be also found in
# <http://www.gnu.org/licenses/gpl.html>.
#
# --------------------------------------------------------------------------
#
$^W++;
use strict;
use Getopt::Long;
use Date::Pcalc;
use Cwd;
#
my $fort61freq=0;    # output frequency in SECONDS
my $fort62freq=0;    # output frequency in SECONDS
my $fort63freq=0;    # output frequency in SECONDS
my $fort64freq=0;    # output frequency in SECONDS
my $fort7172freq=0;  # output frequency in SECONDS
my $fort7374freq=0;  # output frequency in SECONDS
my ($fort61, $fort62, $fort63, $fort64, $fort7172, $fort7374);
my $hsformat="binary";  # input param for hotstart format: binary or netcdf
my ($fort61netcdf, $fort62netcdf, $fort63netcdf, $fort64netcdf, $fort7172netcdf, $fort7374netcdf); # for netcdf (not ascii) output
my $hotswan;            # "off" if swan has to be cold started (only on first nowcast)
our $netcdf4;           # if defined, then netcdf files should use netcdf4 formatting
#
my $controltemplate;
my $elevstations="null"; # file containing list of adcirc elevation stations
my $velstations="null";  # file with list of adcirc velocity stations
my $metstations="null";  # file with list of adcirc meteorological stations
my $swantemplate;
my $metfile;
my $gridname="nc6b";
our $csdate;
our ($cy, $cm, $cd, $ch, $cmin, $cs);  # ADCIRC cold start time
our ($ny, $nm, $nd, $nh, $nmin, $ns);  # current ADCIRC time
our ($oy, $om, $od, $oh, $omin, $os);  # OWI start time
our ($ey, $em, $ed, $eh, $emin, $es);  # Main Event start time
our ($Eny,$Enm,$End,$Enh,$Enmin,$Ens); # End of simulation
my $numelevstations="0"; # number and list of adcirc elevation stations
my $numvelstations="0";  # number and list of adcirc velocity stations
my $nummetstations="0";  # number and list of adcirc meteorological stations
my $startdatetime; # formatted for swan fort.26
my $enddatetime;   # formatted for swan fort.26
my $hstime;        # time, in seconds, of hotstart file (since coldstart)
my $hstime_days;   # time, in days, of hotstart file (since coldstart)
our $endtime;      # time at which the run should end (days since coldstart)
our $dt=3.0;       # adcirc time step, in seconds
my $swandt=600.0;  # swan time step, in seconds
my $bladj=0.9;
our $enstorm;      # Simulation specification
my $tau=0;         # 
my $dir=getcwd();
my $nws=9.0;
our $stormDir;       # Run directory                                   
my $scriptdir = "."; # the directory containing main.sh
our $NHSINC;    # time step increment at which to write hot start files
our $NHSTAR;    # writing and format of ADCIRC hotstart output file
our $RNDAY;     # total run length from cold start, in days
my $nffr = -1;  # for flux boundaries; -1: top of fort.20 corresponds to hs
my $ihot;       # whether or not ADCIRC should READ a hotstart file
our $wtiminc;   # parameters related to met and wave timing
our $rundesc;       # description of run, 1st line in fort.15
our $RUNID;    # run id, 2nd line in fort.15. 2nd line in fort.15
our $waves = "off"; # set to "on" if adcirc is coupled with swan is being run
my ($m2nf, $s2nf, $n2nf, $k2nf, $k1nf, $o1nf, $p1nf, $q1nf); # nodal factors
my ($m2eqarg, $s2eqarg, $n2eqarg, $k2eqarg, $k1eqarg, $o1eqarg, $p1eqarg, $q1eqarg); # equilibrium arguments
my $met;		# multi-stage: type of stage one simulation
my $windInterval;       # multi-stage: Reading wind interval from config
my $eventdate;
my $bctype;
my $S2SPINUP;
my $RNDAY_met;
my $ID;                # The run ID
my $estuary;           # the name of the estuary
my $nddlAttribute;     # Specifying if nodal attribute is being used,
my $fricType;          # SWAN BOTTOM FRICTION TYPE
my $platform;
my ($line_1,$line_2,$line_3,$line_4,$line_5,$line_6,$line_7,$line_8,$line_9,$line_10);
my $nwset;             # Basin (and regional) met nws=12
#
GetOptions("controltemplate=s" => \$controltemplate,
           "stormdir=s" => \$stormDir,
           "swantemplate=s" => \$swantemplate,
           "elevstations=s" => \$elevstations,
           "velstations=s" => \$velstations,
           "metstations=s" => \$metstations,
           "metfile=s" => \$metfile,
           "name=s" => \$enstorm,
           "gridname=s" => \$gridname,
           "cst=s" => \$csdate,
           "endtime=s" => \$endtime,
           "dt=s" => \$dt,
           "swandt=s" => \$swandt,
           "bladj=s" => \$bladj,
           "nws=s" => \$nws,
           "hstime=s" => \$hstime,
           "scriptdir=s" => \$scriptdir,
           "fort61freq=s" => \$fort61freq,
           "fort62freq=s" => \$fort62freq,
           "fort63freq=s" => \$fort63freq,
           "fort64freq=s" => \$fort64freq,
           "fort7172freq=s" => \$fort7172freq,
           "fort7374freq=s" => \$fort7374freq,
           "fort61netcdf" => \$fort61netcdf,
           "fort62netcdf" => \$fort62netcdf,
           "fort63netcdf" => \$fort63netcdf,
           "fort64netcdf" => \$fort64netcdf,
           "fort7172netcdf" => \$fort7172netcdf,
           "fort7374netcdf" => \$fort7374netcdf,
           "netcdf4" => \$netcdf4,
           "hsformat=s" => \$hsformat,
           "hotswan=s" => \$hotswan,
           "met=s" => \$met,
           "windInterval=s" => \$windInterval,
           "bctype=s" => \$bctype,
           "eventdate=s" => \$eventdate,
           "stage2_spinUp=s" =>\$S2SPINUP,
           "ID=s" => \$ID,
           "estuary=s" => \$estuary, 
           "nddlAttribute=s" => \$nddlAttribute,
           "swanBottomFri=s" => \$fricType,
           "platform=s" => \$platform,
           "nwset=s" => \$nwset
           );
#
# parse out the pieces of the cold start date
$csdate=~ m/(\d\d\d\d)(\d\d)(\d\d)(\d\d)/;
$cy = $1;
$cm = $2;
$cd = $3;
$ch = $4;
$cmin = 0.0;
$cs = 0.0;
#
# initialize "now" to a reasonable value
$ny = $1;
$nm = $2;
$nd = $3;
$nh = $4;
$nmin = $cmin;
$ns = $cs;
#
# determine whether SWAN has been turned on
my $waves_digit = int($nws / 100);
if ( abs($waves_digit) == 3 ) {
   $waves = "on";
   stderrMessage("INFO","Wave forcing is active.");
}
#
#----------------------------------------------------
#
#  A D C I R C   C O N T R O L   F I L E
#
# open template file for fort.15
unless (open(TEMPLATE,"<$controltemplate")) {
   stderrMessage("ERROR","Failed to open the fort.15 template file $controltemplate for reading: $!.");
   die;
}
#
# open output control file
if ( $stormDir eq "null" ) {
   stderrMessage("Fatal","Failed to read run directory");
   die;
}
unless (open(STORM,">$stormDir/fort.15")) {
   stderrMessage("ERROR","Failed to open the output control file $stormDir/fort.15: $!");
   die;
}
stderrMessage("INFO","The fort.15 file will be written to the directory $stormDir.");
#
# call subroutine that knows how to fill in the fort.15 for each particular
# type of forcing
if ( abs($nws) == 12 || abs($nws) == 312 ) {
   &writefort22();
}
#
# ----------------------------------------------------
#
# Specifiyinh 1)run.description, 2)runday, 3)wind interval
# Run day is used in creating tidal node factor and equilibrium. 
# For simulations creating hotstart file, the run day will be 
# set to the date in which HSF is written (after tide section )
# to avoid continuing simulation after HSF created.
#
stderrMessage("INFO","Setting run days, run descriptions, and wind intervals (for nws 12)");
if ( $enstorm eq "S1.gridded" ) {
   $rundesc = "MultiStage: Stage 1";
   $RUNID = "Single $endtime day run for gridded met";
}
if ( $met eq "NHC" ) {
   $rundesc = "Multi-stage: Stage 1";
   if ( $enstorm eq "S1_1_NHC" ) {
      $RUNID = "Tide only NHC";
   }
   if ( $enstorm eq "S1_2_NHC" ) {
   $RUNID = "Tide and Met NHC";
   }
}
#
if ( $enstorm eq "S2.gridded" ) {
   $rundesc = "Multi-stage: Stage 2";
   $RUNID = "Single $endtime day run";
}
if ( $enstorm eq "S2_1_NHC" ) {
    $rundesc = "Multi-stage: Stage 2";
    $RUNID = "Tide only NHC";
}
if ( $enstorm eq "S2_2_NHC" ) {
   $rundesc = "Multi-stage: Stage 2";
   $RUNID = "Tide and Met NHC";
}
#
if ( $enstorm eq "S1.gridded" || $enstorm eq "S2_gridded" ) {
   $wtiminc = $windInterval;
}
if ( $enstorm eq "S1_1_NHC" || $enstorm eq "S2_1_NHC" ) {
   $wtiminc = "NO LINE HERE";
}   
#   S1_2_NHC and S2_2_NHC specified some lines below
#
# ----------------------------------------------------------------------------
my $diff_event;
my $start_output;
my $start_output_day;
#
#                   OUTPUTING STAGE ONE FOR EXCTRACTING BC            
#
# Calculate the difference between event start time and cold start time
# following by subtracting HRLA domain spin-up day to determine at which day
# after coldstart the elevation (or flux) output is written.
# Stage two boundary forcing is extracted from elevation (or flux) output.
   $eventdate =~ m/(\d\d\d\d)(\d\d)(\d\d)(\d\d)/;
   $ey = $1;
   $em = $2;
   $ed = $3;
   $eh = $4;
   $emin = 0;
   $es = 0;
#
# get difference
   (my $Edays, my $Ehrs, my $Emin, my $Esec)
         = Date::Pcalc::Delta_DHMS(
              $cy,$cm,$cd,$ch,0,0,
              $ey,$em,$ed,$eh,0,0);
# find the difference in seconds
   $diff_event = $Edays*86400.0 + $Ehrs*3600.0 + $Emin*60.0 + $Esec;
   $start_output = $diff_event - $S2SPINUP*86400.0;
   $start_output_day = $start_output/86400.0;#
   # This is also the start day of the stage 2
   stderrMessage("INFO","Stage one will wirte boundary condition at day '$start_output_day'.");
#
# Calculating the start date of the stage 2 (used in swan start time & creating new fort.22 for NHC if S2SpinUp < 0)
   our ($s2cy,$s2cm,$s2cd,$s2ch,$s2cmin,$s2cs) =
            Date::Pcalc::Add_Delta_DHMS ($cy,$cm,$cd,$ch,0,0,$start_output_day,0,0,0) ;
if ( $enstorm eq "S2_1_NHC" || $enstorm eq "S2_2_NHC" ) {
   my $S2SD=sprintf("%4d%02d%02d%02d",$s2cy,$s2cm,$s2cd,$s2ch);
   stderrMessage("INFO","Stage two start date is '$S2SD' ");
if ( $enstorm eq "S2_2_NHC" && $S2SPINUP ge 0 ) {
   $start_output = $diff_event ; 
   $start_output_day = $start_output/86400.0;
   our ($s2cy,$s2cm,$s2cd,$s2ch,$s2cmin,$s2cs) =
           Date::Pcalc::Add_Delta_DHMS ($cy,$cm,$cd,$ch,0,0,$start_output_day,0,0,0) ;
   my $S2SD=sprintf("%4d%02d%02d%02d",$s2cy,$s2cm,$s2cd,$s2ch);
   stderrMessage("DEBUG","Stage two start date is '$S2SD' ");
}  
} 
#
# RUNDAY ==> gridded met nws=12 (312)
if ( $enstorm eq "S1.gridded" ) {
   $RNDAY = $endtime ;
}
if ( $enstorm eq "S2.gridded" ) {
     $RNDAY = $endtime - $start_output_day ;
}
#
# RUNDAY ==> NHC met nws=19/20 
if ( $enstorm eq "S1_1_NHC" || $enstorm eq "S1_2_NHC" ) {
   $RNDAY = $endtime;
}
if ( $enstorm eq "S2_1_NHC" || $enstorm eq "S2_2_NHC" ) {
     $RNDAY = $endtime - $start_output_day ;
}
#
# Specifying wtiminc for NHC 
if ( $enstorm eq "S2_2_NHC" || $enstorm eq "S1_2_NHC" ) {
$wtiminc = $cy." ".$cm." ".$cd." ".$ch." 1 ".$bladj;
if ( abs($nws) == 20 || abs($nws) == 320 ) {
   $wtiminc .= " 1 ";
}
}
# 
# Reading the RNday which is in days, added to event start date, 
# convert it to date (SWAN end date and calculating blank will use this)
$NHSINC = int(($RNDAY*86400.0)/$dt);
   ($Eny,$Enm,$End,$Enh,$Enmin,$Ens) =
        Date::Pcalc::Add_Delta_DHMS($cy,$cm,$cd,$ch,$cmin,$cs,$endtime,0,0,0);
# For S1_1_NHC
# Comparing Event start and Output start
# If Event > Output; writing for.63 starts in S1_1_NHC (S2SPINUP > 0)
# if Event < Output; writing fort.63 starts in S1_2_NHC (S2SPINUP =< 0)
# Will applied in output writing section     
# ---------------------------------------------------------------------------
# 
#        HOT START CONTROL (TC requres)
#
if ( $enstorm eq "S1_1_NHC") {   
   stderrMessage("INFO","...");
   stderrMessage("INFO","Setting hotstart time step for tide only stage 1 (NHC)"); 
   $NHSTAR = 1;
   $NHSINC = $diff_event/$dt;  
} elsif ( $enstorm eq "S2_1_NHC" ) { # in case of non-zero S2SPINUP
   stderrMessage("INFO","...");
   stderrMessage("INFO","Setting hotstart time step for tide only stage  2 (NHC)");
   $NHSTAR = 1;
   $NHSINC = $diff_event/$dt - $S2SPINUP*24.0*3600.0/$dt; 
} else {
   $NHSTAR = 0;
   $NHSINC = 99999;
}
#
   if ( $hstime eq "on" ) {
   stderrMessage("INFO","...");
   stderrMessage("INFO","Setting ihot to hotstart for tide&met stage 1 & 2 (NHC)");
   $ihot = 67;
   if ( $hsformat eq "netcdf" ) {
      $ihot = 367;
      if ( defined $netcdf4 ) {
         $ihot = 567;
      }
   }
} else {
   $ihot = 0;
   $nffr = 0;
}
# ----------------------------------------------------------------------------
#
#       SETTING OUTPUT PARAMETERS
#
my $fort61specifier = &getSpecifier($fort61freq,$fort61netcdf);
my $fort62specifier = &getSpecifier($fort62freq,$fort62netcdf);
$fort61 = $fort61specifier . " 0.0 365.0 " . &getIncrement($fort61freq,$dt);
$fort62 = $fort62specifier . " 0.0 365.0 " . &getIncrement($fort62freq,$dt);
#
my $fort63specifier = &getSpecifier($fort63freq,$fort63netcdf);
my $fort64specifier = &getSpecifier($fort64freq,$fort64netcdf);
#
# 
# ********* Stage two accepts every type of output specification
#
if ( $enstorm eq "S2.gridded" || ( $enstorm eq "S1_1_NHC" && $S2SPINUP lt 0 ) || ( $enstorm eq "S2_1_NHC" && $S2SPINUP lt 0 ) || $enstorm eq "S2_2_NHC" ) {
   $fort63 = $fort63specifier . " 0.0 365.0 " . &getIncrement($fort63freq,$dt);
   $fort64 = $fort64specifier . " 0.0 365.0 " . &getIncrement($fort64freq,$dt);
}
#
# ******** Stage one only requires fort.63 or fort.64 output
#
if ( ( $enstorm eq "S1_1_NHC" && $S2SPINUP ge 0 ) || ( $enstorm eq "S2_1_NHC" && $S2SPINUP ge 0 )) {
   if ( $bctype eq "elevation" ) {
   $fort63 = $fort63specifier . " " .  $start_output_day . " " . $endtime . " " .  &getIncrement($fort63freq,$dt);
   $fort64 = $fort64specifier . " 0.0 365.0 " . &getIncrement($fort64freq,$dt); 
   #
   if ( $bctype eq "flux" ) {
   $fort63 = $fort63specifier . " 0.0 365.0 " . &getIncrement($fort63freq,$dt);
   $fort64 = $fort64specifier . " " .  $start_output_day . " " . $endtime . " " .  &getIncrement($fort64freq,$dt);
   }
   }
}
#
if ( $enstorm eq "S1.gridded" || $enstorm eq "S1_2_NHC" ) { 
   if ( $bctype eq "elevation" ) {
   $fort63 = $fort63specifier . " " .  $start_output_day . " " . $endtime . " " .  &getIncrement($fort63freq,$dt);
   $fort64 = $fort64specifier . " 0.0 365.0 " . &getIncrement($fort64freq,$dt);
   #
   if ( $bctype eq "flux" ) {
   $fort63 = $fort63specifier . " 0.0 365.0 " . &getIncrement($fort63freq,$dt);
   $fort64 = $fort64specifier . " " .  $start_output_day . " " . $endtime . " " .  &getIncrement($fort64freq,$dt);
   }
   }
}  
#
my $fort7172specifier = &getSpecifier($fort7172freq,$fort7172netcdf);
my $fort7374specifier = &getSpecifier($fort7374freq,$fort7374netcdf);
#
$fort7172 = $fort7172specifier . " 0.0 365.0 " . &getIncrement($fort7172freq,$dt);
$fort7374 = $fort7374specifier . " 0.0 365.0 " . &getIncrement($fort7374freq,$dt);
if ( $nws eq "0" || $enstorm eq "S1_1_NHC" ) {
   $fort7172 = "NO LINE HERE";
   $fort7374 = "NO LINE HERE";
} 
# ----------------------------------------------------------------------------
# add swan time step to WTIMINC line if waves have been activated
if ( $waves eq "on" ) {
   $wtiminc.=" $swandt"
}
# ----------------------------------------------------------------------------
#
#         GENERATING TIDES 
#
# determine if tide_fac.x executable is present, and if so, generate
# nodal factors and equilibrium arguments
my $tides = "off";
if ( $enstorm eq "S1.gridded" || $enstorm eq "S1_1_NHC" || $enstorm eq "S1_2_NHC" ) {
if ( -e "$scriptdir/tides/tide_fac.x" && -x "$scriptdir/tides/tide_fac.x" ) {
   my $tide_fac_message = `$scriptdir/tides/tide_fac.x --length $RNDAY --year $cy --month $cm --day $cd --hour $ch --outputformat simple --outputdir $stormDir`;
   if ( $tide_fac_message =~ /ERROR|WARNING/ ) {
      stderrMessage("WARNING","There was an issue when running $scriptdir/tides/tide_fac.x: $tide_fac_message.");
   } else {
      stderrMessage("INFO","Nodal factors and equilibrium arguments were written to the file $stormDir/tide_fac.out.");
      # open data file
      unless (open(TIDEFAC,"<$stormDir/tide_fac.out")) {
         stderrMessage("ERROR","Failed to open the file '$enstorm/tide_fac.out' for reading: $!.");
         die;
      }
      # parse out nodal factors and equilibrium arguments from the
      # various constituents
      $tides = "on";
      stderrMessage("INFO","Parsing tidal node factors and equilibrium arguments.");
      while(<TIDEFAC>) {
         my @constituent = split;
         if ( $constituent[0] eq "M2" ) {
            $m2nf = $constituent[1];
            $m2eqarg = $constituent[2];
         } elsif ( $constituent[0] eq "S2" ) {
            $s2nf = $constituent[1];
            $s2eqarg = $constituent[2];
         } elsif  ( $constituent[0] eq "N2" ) {
            $n2nf = $constituent[1];
            $n2eqarg = $constituent[2];
         } elsif ( $constituent[0] eq "K2" ) {
            $k2nf = $constituent[1];
            $k2eqarg = $constituent[2];
         } elsif ( $constituent[0] eq "K1" ) {
            $k1nf = $constituent[1];
            $k1eqarg = $constituent[2];
         } elsif ( $constituent[0] eq "O1" ) {
            $o1nf = $constituent[1];
            $o1eqarg = $constituent[2];
         } elsif ( $constituent[0] eq "P1" ) {
            $p1nf = $constituent[1];
            $p1eqarg = $constituent[2];
         } elsif ( $constituent[0] eq "Q1" ) {
            $q1nf = $constituent[1];
            $q1eqarg = $constituent[2];
         } else {
            stderrMessage("WARNING","Tidal constituent named '$constituent[0]' was unrecognized.");
         }
      }
      close(TIDEFAC);
   }
} else {
   stderrMessage("INFO","The executable that generates the tidal node factors and equilibrium arguments ($scriptdir/tides/tide_fac.x) was not found. Updated nodal factors and equilibrium arguments will not be generated.");
}
}
#
# load up stations
$numelevstations = &getStations($elevstations,"elevation");
$numvelstations = &getStations($velstations,"velocity");
if ( $nws eq "0" ) {
   stderrMessage("INFO","NWS is zero; meteorological stations will not be written to the fort.15 file.");
   $nummetstations = "NO LINE HERE";
} else {
   $nummetstations = &getStations($metstations,"meteorology");
}
# ---------------------------------------------------------------------------------------
#
# First of all, correcting the RUNDAY for runs producing hotstart. 
# Avoid in the first place for create correct tides that depends on the runday too.
if ( $enstorm eq "S1_1_NHC" || $enstorm eq "S2_1_NHC" ) {
   $RNDAY = $NHSINC*$dt/(24.0*3600.0);
}
#
# SETTING last 10 lines in the fort.15 if netcdf output specified,
#
my $netcdf;
if ( $enstorm eq "S2.gridded" || $enstorm eq "S2_2_NHC" ) {
   if ( defined $netcdf || defined $netcdf4 ) {
      $line_1 = $ID ;                # Project title
      $line_2 = "FIT";               # Project institute
      $line_3 = $platform;           # Project source
      $line_4 = "MultiStage";        # Project history
      $line_5 = "https://github.com/ptaeb2014/Multi-stage";      # Project Ref
      $line_6 = "Adjusted conventional one way, C1W, nesting for coastal estuarine modeling";  # Project Comments
      $line_7 = $platform ;                                      # Project Host,
      $line_8 = "CF" ;                                           # Convention
      $line_9 = 'ptaeb2014@my.fit.edu' ;                         # Contact Information,
      $line_10= sprintf("%4d%02d%02d %02d:%02d UTC",$cy,$cm,$cd,$ch,$cmin) ; # Project Coldstart time
   } else {
          $line_1 = "NO LINE HERE";
          $line_2 = "NO LINE HERE";
          $line_3 = "NO LINE HERE";
          $line_4 = "NO LINE HERE";
          $line_5 = "NO LINE HERE";
          $line_6 = "NO LINE HERE";
          $line_7 = "NO LINE HERE";
          $line_8 = "NO LINE HERE";
          $line_9 = "NO LINE HERE";
          $line_10= "NO LINE HERE";
   }
}
# 
# WRITING ADCIRC AND SWAN CONTROL FILE
stderrMessage("INFO","Filling in ADCIRC control template (fort.15).");
while(<TEMPLATE>) {
    # if we are looking at the first line, fill in the name of the storm
    # and the advisory number, if available
    s/%StormName%/$rundesc/;
    # if we are looking at the DT line, fill in the time step (seconds)
    s/%DT%/$dt/;
    # if we are looking at the RNDAY line, fill in the total run time (days)
    s/%RNDAY%/$RNDAY/;
    # set whether or not we are going to read a hotstart file
    s/%IHOT%/$ihot/;
    # fill in the parameter that selects which wind model to use
    s/%NWS%/$nws/;
    # fill in the parameter that selects which wind model to use
    s/%NFFR%/$nffr/;
    # fill in nodal factors and equilibrium arguments
    if ( $tides eq "on" ) {
       s/%M2NF%/$m2nf/; s/%M2EQARG%/$m2eqarg/;
       s/%S2NF%/$s2nf/; s/%S2EQARG%/$s2eqarg/;
       s/%N2NF%/$n2nf/; s/%N2EQARG%/$n2eqarg/;
       s/%K2NF%/$k2nf/; s/%K2EQARG%/$k2eqarg/;
       s/%K1NF%/$k1nf/; s/%K1EQARG%/$k1eqarg/;
       s/%O1NF%/$o1nf/; s/%O1EQARG%/$o1eqarg/;
       s/%P1NF%/$p1nf/; s/%P1EQARG%/$p1eqarg/;
       s/%Q1NF%/$q1nf/; s/%Q1EQARG%/$q1eqarg/;
    }
    # fill in the timestep increment that hotstart files will be written at
    s/%NHSINC%/$NHSINC/;
    # fill in whether or not we want a hotstart file out of this
    s/%NHSTAR%/$NHSTAR/;
    # fill in ensemble name -- this is in the comment line
    s/%RUNID%/${RUNID}/;
    # may be asymmetric parameters, or wtiminc, rstiminc, etc
    s/%WTIMINC%/$wtiminc/;
    # elevation stations
    s/%NUMELEVSTATIONS%/$numelevstations/;
    # velocity stations
    s/%NUMVELSTATIONS%/$numvelstations/;
    # meteorological stations
    s/%NUMMETSTATIONS%/$nummetstations/;
    # output options
    s/%FORT61%/$fort61/;
    s/%FORT62%/$fort62/;
    s/%FORT63%/$fort63/;
    s/%FORT64%/$fort64/;
    s/%FORT7172%/$fort7172/;
    s/%FORT7374%/$fort7374/;
    # netcdf
    s/%NCPROJ%/$line_1/;
    s/%NCINST%/$line_2/;
    s/%NCSOUR%/$line_3/;
    s/%NCHIST%/$line_4/;
    s/%NCREF%/$line_5/;
    s/%NCCOM%/$line_6/;
    s/%NCHOST%/$line_7/;
    s/%NCCONV%/$line_8/;
    s/%NCCONT%/$line_9/;
    s/%NCDATE%/$line_10/;
    unless (/NO LINE HERE/) {
       print STORM $_;
    }
}
close(TEMPLATE);
close(STORM);
#
# -----------------------------------------------------------------------------
#                       
#                       S W A N   C O N T R O L   F I L E
#
if ( $waves eq "on" ) {
   # open template file for fort.26
   unless (open(TEMPLATE,"<$swantemplate")) {
      stderrMessage("ERROR","Failed to open the swan template file $swantemplate for reading: $!.");
      die;
   }
   #
   # open output fort.26 file
   unless (open(STORM,">$stormDir/fort.26")) {
      stderrMessage("ERROR","Failed to open the output control file $stormDir/fort.26: $!.");
      die;
   }
   stderrMessage("INFO","The fort.26 file will be written to the directory $stormDir.");
   #
   $startdatetime = sprintf("%4d%02d%02d.%02d0000",$s2cy,$s2cm,$s2cd,$s2ch);
   $enddatetime = sprintf("%4d%02d%02d.%02d0000",$Eny,$Enm,$End,$Enh);
   my $swanhs =  "INIT HOTSTART MULTIPLE 'swan.68'";
   if ( $hotswan eq "off" ) {
      $swanhs = "\$ swan will coldstart";
   }
   #
   stderrMessage("INFO","Filling in swan control template (fort.26).");
   while(<TEMPLATE>) {
       # Run ID
       s/%ID%/$ID/;
       # The name of the coastal estuary
       s/%estuary%/${estuary}/;
       # may be asymmetric parameters, or wtiminc, rstiminc, etc
       s/%WTIMINC%/$wtiminc/;
       #
       # s/%hotstart%/$swanhs/;
       if ( $nddlAttribute eq "on" ) {
	  s/%ADCFRI%/INPGRID FR   UNSTRUCTURED EXCEPTION 0.05 NONSTAT  %startdatetime% %swandt% SEC %enddatetime%/; 
          s/%READFRI%/READINP ADCFRIC/;
          s/%FRICTYPE%//;
       } else { 
          s/%ADCFRI%/NO LINE HERE/;
          s/%READFRI%/NO LINE HERE/;
          s/%FRICTYPE%/$fricType/;
       }
       # if we are looking at the DT line, fill in the time step (seconds)
       s/%swandt%/$swandt/;
       # swan start time -- corresponds to adcirc hot start time
       s/%startdatetime%/$startdatetime/;
       # swan end time%
       s/%enddatetime%/$enddatetime/;
       unless (/NO LINE HERE/) {
          print STORM $_;
       }
   }
   close(TEMPLATE);
   close(STORM);
}
#
#--------------------------------------------------------------------------
#   S U B   G E T   S P E C I F I E R
#
# Determines the correct output specifier for output files based on
# the output frequency, 
# and whether or not the netcdf format is used (ascii is the default).
#--------------------------------------------------------------------------
sub getSpecifier () {
   my $freq = shift;
   my $netcdf = shift;
   my $specifier;
   #
   # S1_1_NHC
   if ( $enstorm eq "S1_1_NHC" && $S2SPINUP le 0 ) {
      $specifier = "0";
   }
   if ( $enstorm eq "S1_1_NHC" && $S2SPINUP gt 0 ) {
      $specifier = "-1";
   }
   # S1_2_NHC
   if ( $enstorm eq "S1_2_NHC" && $S2SPINUP le 0 ) {
      $specifier = "-1";
   }
   if ( $enstorm eq "S1_2_NHC" && $S2SPINUP gt 0 ) {
      $specifier = "-1";
   }
   if ( $enstorm eq "S2_1_NHC" && $S2SPINUP gt 0 ) {
      $specifier = "-1";
   }
   if ( $enstorm eq "S2_2_NHC" ) {
      $specifier = "1";
   } 
   #
   #
   if ( $freq == 0 ) {
      $specifier = "0";
   } else {
   # S1 and S2 gridded
      if ( $enstorm eq "S1.gridded" || $enstorm eq "S2.gridded" ) {
          $specifier = "-1";
      } 
      if ( $enstorm eq "S2.gridded" || $enstorm eq "S2_2_NHC" ) {
         if ( defined $netcdf ) {
            if ( defined $netcdf4 ) {
               $specifier = 5;
            } else {
               $specifier = 3;
            }
         }
      }
   }
   return $specifier;
}
#
#--------------------------------------------------------------------------
#   S U B   G E T   I N C R E M E N T
#
# Determines the correct time step increment based on the output frequency
# and time step size.
#--------------------------------------------------------------------------
sub getIncrement () {
   my $freq = shift;
   my $timestepsize = shift;
   my $increment;
   if ( $freq == 0 ) {
      $increment = "99999";
   } else {
      $increment = int($freq/$timestepsize);
   }
   return $increment;
}
#
#--------------------------------------------------------------------------
#   S U B   G E T   S T A T I O N S
#
# Pulls in the stations from an external file.
#--------------------------------------------------------------------------
sub getStations () {
   my $station_file = shift;
   my $station_type = shift;
#
   my $numstations = "";
   my $station_var = "NSTAE";
   if ( $station_type eq "velocity" ) {
      $station_var = "NSTAV";
   }
   if ( $station_type eq "meteorology" ) {
      $station_var = "NSTAM";
   }
   if ( $station_file =~ /null/) {
      $numstations = "0   ! $station_var" ;
      stderrMessage("INFO","There are no $station_type stations.");
      return $numstations; # early return
   }
   $numstations = `wc -l $station_file`;
   $numstations =~ /^(\d+)/;
   my $number = $1;
   stderrMessage("INFO","There are $number $station_type stations in the file '$station_file'.");
   unless (open(STATIONS,"<$station_file")) {
      stderrMessage("ERROR","Failed to open the $station_type stations file $station_file for reading: $!.");
      die;
   }
   chomp($numstations);
   # need to add this as a sort of comment in the fort.15 for the post
   # processing script station_transpose.pl to find
   $numstations = $numstations . " " . $station_var . "\n";
   while (<STATIONS>) {
      $numstations.=$_;
   }
   close(STATIONS);
   chomp($numstations);
   return $numstations;
}
#
#--------------------------------------------------------------------------
#   S U B   writing fort.22 for NWS 12 (312)
#
# Determines parameter values for the control file when running
# ADCIRC with OWI formatted meteorological data (NWS12).
#--------------------------------------------------------------------------
sub writefort22 () {
   #
   # 1- Open fort.221
   # 2- Read the header and obtain the start and end time/date [Required the header to be like starttime endtime] no more info!
   # 3- Use the end/start to calculate the blank number
   #
   $wtiminc = $windInterval;    # to calculate the nwbs
   #
   # Open fort.221 to read the start time, 
   # Extracting the start and end date and time of the .221/222 files for the header!
   # start time is used to calculate the nwbs
   #
   my $windfile = 'fort.221' ;
   open( my $header, '<:encoding(UTF-8)',$windfile)
       or die "ERROR: control_file_gen.pl: Failed to open OWI (NWS12) file $stormDir/fort.221 for reading the start time: $!.";
   my $row = <$header>;
   printf "$row\n";
   my @windinterval = split ' ',$row;
   printf "$windinterval[0]\n";
   #
   close($windfile);
   # 
   my $owistart = $windinterval[0]; 
   my $owiend = $windinterval[1];
   stderrMessage("INFO","The OWI file starts at '$owistart'.");
   stderrMessage("INFO","The OWI file ends at '$owiend'.");
   $owiend =~ m/(\d\d\d\d)(\d\d)(\d\d)(\d\d)/;
   # -----------------------------------------------
   #
   # Calculating blank time snap 
   #
   $rundesc = "cs:$csdate"."0000 cy:$owistart multi-stage wind";
   $owistart =~ m/(\d\d\d\d)(\d\d)(\d\d)(\d\d)/;
   $oy = $1;
   $om = $2;
   $od = $3;
   $oh = $4;
   $omin = 0;
   $os = 0;
   #
   # get difference for state 1
   (my $ddays, my $dhrs, my $dmin, my $dsec)
           = Date::Pcalc::Delta_DHMS(
                $cy,$cm,$cd,$ch,0,0,
                $oy,$om,$od,$oh,0,0);
   #
   $eventdate =~ m/(\d\d\d\d)(\d\d)(\d\d)(\d\d)/;
   $ey = $1;
   $em = $2;
   $ed = $3;
   $eh = $4;
   $emin = 0;
   $es = 0;
   #
   # find the difference in seconds
   my $blank_time;
   if ( $enstorm eq "S1.gridded" ) {
      $blank_time = $ddays*86400.0 + $dhrs*3600.0 + $dmin*60.0 + $dsec;
   }
   if ( $enstorm eq "S2.gridded" ) {
      $blank_time = $S2SPINUP*24.0*3600.0 ;
   }
   stderrMessage("INFO","Blank time is '$blank_time'.");
   # calculate the number of blank snaps (or the number of
   # snaps to be skipped in the OWI file if it starts before the
   # current time in the ADCIRC run)
   my $nwbs = int($blank_time/$wtiminc);
   stderrMessage("INFO","nwbs is '$nwbs'");
   #
   # create the fort.22 output file, which is the wind input file for ADCIRC
   open(MEMBER,">$stormDir/fort.22") || die "ERROR: control_file_gen.pl: Failed to open file for ensemble member '$enstorm' to write $stormDir/fort.22 file: $!.";
   printf MEMBER "$nwset\n";  # nwset
   printf MEMBER "$nwbs\n";   # nwbs
   printf MEMBER "1.0\n";     # dwm
   printf MEMBER "fort.221\n";   # basin pressure
   printf MEMBER "fort.222\n";   # basin wind
   printf MEMBER "fort.223\n";   # regional pressure : not used if regional not specified
   printf MEMBER "fort.224\n";   # regional wind     : not used if regional not specified
   close(MEMBER);
   #
}
#
#--------------------------------------------------------------------------
#   S U B   S T D E R R  M E S S A G E
#
# Writes a log message to standard error.
#--------------------------------------------------------------------------
sub stderrMessage () {
   my $level = shift;
   my $message = shift;
   my @months = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
   (my $second, my $minute, my $hour, my $dayOfMonth, my $month, my $yearOffset, my $dayOfWeek, my $dayOfYear, my $daylightSavings) = localtime();
   my $year = 1900 + $yearOffset;
   my $hms = sprintf("%02d:%02d:%02d",$hour, $minute, $second);
   my $theTime = "[$year-$months[$month]-$dayOfMonth-T$hms]";
   printf STDERR "$theTime $level: control_file_gen.pl: $message\n";
   if ($level eq "ERROR") {
      sleep 60
   }
}
