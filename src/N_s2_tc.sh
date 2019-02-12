#!/bin/bash
#
# Stage 2
# Background met.
# nowcast
#
SYSLOG=$1
CONFIG=$2
cycle=$3
. ${CONFIG}
. ${mainDIR}/src/logging.sh
# ---------------------------------------------------------------------------
#                       WRITING  FORT.15 AND FORT.22 
#
writeControls()
{ cntrloptn=$1            # control option
  rndr=$2                 # run directory
  # Linking control writer Perl to run dir.
  ln -fs $mainDIR/utility/control_file_gen.pl  $rndr/control_file_gen.pl
  # linking Pcalc.pm and ArraySub.pm
  ln -fs $mainDIR/utility/PERL/Date            $rndr/Date
  ln -fs $mainDIR/utility/PERL/ArraySub.pm     $rndr/ArraySub.pm
  #
  logMessage "Constructing control file in $rndr with following options:"
  echo "       $CONTROLOPTIONS" >> ${SYSLOG} 2>&1
  echo "" >> ${SYSLOG} 2>&1
  cd $rndr
  # use $CONTROLOPTIONS, don't use $cntrloptn
  perl $rndr/control_file_gen.pl $CONTROLOPTIONS >> ${SYSLOG} 2>&1
  cd -
}
# ---------------------------------------------------------------------------------
# 
#                         ADCPREP: DECOMPOSING INPUTS
# 
prepFile()
{ JOBTYPE=$1
   . $CONFIG
   ln -fs $EXEDIR/adcprep $RUNDIR/adcprep
   cd $RUNDIR
   ./adcprep --np $NCPU --${JOBTYPE} >> $RUNDIR/adcprep.log 2>&1
   cd -
}
#
# ---------------------------------------------------------------------------------
#                         
#                          PADCIRC: PARALLEL ADCIRC
runPADCIRC()
{ NP=$1
  cd $mainDIR
  . $CONFIG
  ln -s $EXEDIR/padcirc $RUNDIR/padcirc
  cd $RUNDIR
  mpirun -n $NP ./padcirc >> $RUNDIR/padcirc.log 2>&1
  cd -
}
#
# ---------------------------------------------------------------------------------

#                         
#                         PADCSWAN: PARALLEL ADCIRC + SWAN
runPADCSWAN()
{ NP=$1
  cd $mainDIR
  . $CONFIG
  ln -s $EXEDIR/padcswan $RUNDIR/padcswan
  cd $RUNDIR
  mpirun -n $NP ./padcswan >> $RUNDIR/padcswan.log 2>$1
  cd -
}
#
# ------------------------------------------------------------------------------------
#
#                                    MAIN BODY
#
. $CONFIG
workingDIR=$mainDIR$ID
ADVISORY=`cat $mainDIR$ID/currentCycle`
nowcastDIR=$mainDIR$ID/$ADVISORY/nowcast/S1        # of stage one
forecastDIR=$mainDIR$ID/$ADVISORY/forecast/S1      # of stage one
mkdir $mainDIR$ID/$ADVISORY/nowcast/S2
RUNDIR=$mainDIR$ID/$ADVISORY/nowcast/S2
nddlAttribute="off"
#
echo ""  >> ${SYSLOG} 2>&1
echo ""  >> ${SYSLOG} 2>&1
logMessage "Stage 2 -- Tropical Cyclone, nowcast, HRLA in $RUNDIR"
#
hotswan="off"
if [ $cycle -gt 1 ]; then
   lastDIR=`cat $workingDIR/currentCycle.old`
   if [ -e $mainDIR$ID/$lastDIR/nowcast/S2/PE0000/fort.67 ]; then
      ln -fs $workingDIR/$lastDIR/nowcast/S2/PE0000/fort.67 $RUNDIR/fort.67
   elif [ -e $mainDIR$ID/$lastDIR/nowcast/S2/PE0000/fort.68 ]; then
      ln -fs $workingDIR/$lastDIR/nowcast/S2/PE0000/fort.68 $RUNDIR/fort.67
   else
      fatal "Nowcast S2: swan.67/8 not found in $workingDIR/$lastDIR/nowcast/S2/PE0000/"
   fi
   if [[ $WAVES = on ]]; then
      hotswan="on"    # hotstarting swan if hot starting from previous cycle nowcast
  fi
fi
#
# Linking fort.19 to run directory for HRLA
if [ ! -z ${nowcastDIR}/fort.19_1 ]; then
   ln -s ${nowcastDIR}/fort.19_1    $RUNDIR/fort.19
else
   fatal "Non-periodic elevation boundary condition input file does not exist."
fi
#
cd $mainDIR
. $CONFIG
# Linking the stage two grid
ln -s ${s2_INPDIR}/${s2_grd}         $RUNDIR/fort.14
# Linking the stage one nodal attribute if specified
if [[ ! -z $s2_ndlattr && $s2_ndlattr != null ]]; then
   ln -s ${s2_INPDIR}/$s2_ndlattr    $RUNDIR/fort.13       
   nddlAttribute="on"      # For bottom friction in swan
fi
# Link basin met if specified
ln -s ${nowcastDIR}/fort.22       $RUNDIR/fort.22
# Defining/renaming for control options
ENSTORM="nowcast"
stormDir=$RUNDIR
CONTROLTEMPLATE=${s2_cntrl}
GRIDNAME=${s2_grd}
dt=${S2_dt}
BASENWS=20
# setting NWS
if [[ $VORTEXMODEL = ASYMMETRIC ]]; then
   BASENWS=19
fi
if [[ $VORTEXMODEL = SYMMETRIC ]]; then
   BASENWS=8
fi
#
NWS=$BASENWS
if [[ $WAVES = on ]]; then
   NWS=`expr $BASENWS + 300`
   cp ${s2_INPDIR}/swaninit.template         $RUNDIR/swaninit
fi
#
tides="off"
#
if [ $cycle -eq 1 ]; then
   hstime="off"         # Nowcast of the HRLA coldstarts in the 1st cycle
else
   hstime="on"          # Nowcast of the HRLA hotstart from the nowcast of last cycle.
fi
#
cd ${mainDIR}
. ${CONFIG}
#
nowenddate=`cat $RUNDIR/fort.22 | awk -F"," '{print $3}' | head -2 | tail -1`   # will be used as CSDATE in stage two                                   
#
# This will be used as the start date of the stage two nowcast for all cycles
if [ $cycle -eq 1 ]; then
   cat $mainDIR$ID/$ADVISORY/nowcast/S1/fort.22 | awk -F"," '{print $3}' | head -1 > $workingDIR/nowCSDATE   2>> ${SYSLOG}  # will be used as CSDATE in stage two
fi
#
enddate=$nowenddate
CSDATE=`cat $workingDIR/nowCSDATE`               # CSDATE of S2 is the start time of the fort.221/2
#
CONTROLOPTIONS=" --stormDir $stormDir --scriptdir $mainDIR --cst $CSDATE --endtime 0 --dt $dt --hsformat $HOTSTARTFORMAT --controltemplate $s2_INPDIR$CONTROLTEMPLATE $OUTPUTOPTIONS --name $ENSTORM --met $MET --nws $NWS --platform $platform --enddate $enddate --hstime $hstime"
CONTROLOPTIONS="$CONTROLOPTIONS --bctype $BCTYPE --stage2_spinUp $S2SPINUP"
CONTROLOPTIONS="$CONTROLOPTIONS --gridname $GRIDNAME" # for run.properties
if [[ $WAVES = on ]]; then
   swanStart=`ls $mainDIR$ID/$ADVISORY/nowcast/ | grep "NAM" | awk -F"." '{print $1}' | awk -F"_" '{print $2}' | head -1`
   CONTROLOPTIONS="${CONTROLOPTIONS} --swandt $SWANDT --swantemplate ${s2_INPDIR}/${s2_swan26} --hotswan $hotswan --ID $ID --estuary "$estuary" --nddlAttribute $nddlAttribute --swanBottomFri $fricType --swanStart $swanStart"
fi
# writing fort.15 and fort.22
writeControls $CONTROLOPTIONS $RUNDIR
#
# Decomposing grid, control, and nodal attribute file
logMessage "Running adcprep to partition the mesh for $NCPU compute processors."
prepFile partmesh
logMessage "Running adcprep to partition the mesh for $NCPU compute processors."
prepFile prepall
logMessage "Running adcprep to prepare new fort.15 file."
prepFile prep15
#
if [ $cycle -gt 1 ]; then
   if [[ $WAVES = on ]]; then
      logMessage "Starting copy of wahotstart files."
      # copy the subdomain hotstart files over
      # subdomain hotstart files are always binary formatted
      PE=0
      format="%04d"
      while [ $PE -lt $NCPU ]; do
            PESTRING=`printf "$format" $PE`
            if [ -e $workingDIR/$lastDIR/nowcast/S2/PE${PESTRING}/swan.67 ]; then
               cp $workingDIR/$lastDIR/nowcast/S2/PE${PESTRING}/swan.67 $RUNDIR/PE${PESTRING}/swan.68 2>> ${SYSLOG}
            elif [ -e $workingDIR/$lastDIR/nowcast/S2/PE${PESTRING}/swan.68 ]; then
               cp $workingDIR/$lastDIR/nowcast/S2/PE${PESTRING}/swan.68 $RUNDIR/PE${PESTRING}/swan.68 2>> ${SYSLOG}
            else
               fatal "Nowcast S2: swan.67/8 not found in $workingDIR/$lastDIR/nowcast/S2/PEs/"
            fi
            PE=`expr $PE + 1`
      done
      logMessage "Completed copy of subdomain hotstart files."
  fi
fi
#
#
if [ $WAVES == on ]; then
   runPADCSWAN $NCPU
   logMessage "PADCSWAN job is submitted."
else
   runPADCIRC $NCPU
   logMessage "PADCIRC job is submitted."
fi
#
