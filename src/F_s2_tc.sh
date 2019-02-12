#!/bin/bash
#
# Stage 2
# Background met.
# nowcast
#
SYSLOG=$1
CONFIG=$2
startRun=$3
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
nowcastDIR=$mainDIR$ID/$ADVISORY/nowcast/S2        # of stage two
forecastDIR=$mainDIR$ID/$ADVISORY/forecast/S1      # of stage one
mkdir $mainDIR$ID/$ADVISORY/forecast/S2
RUNDIR=$mainDIR$ID/$ADVISORY/forecast/S2
nddlAttribute="off"
#
echo ""  >> ${SYSLOG} 2>&1
echo ""  >> ${SYSLOG} 2>&1
logMessage "Stage 2 -- Background meteorology, forecast, HRLA in $RUNDIR"
# Linking fort.19 to run directory for HRLA
if [ ! -z $forecastDIR/fort.19_2 ]; then
   ln -s $forecastDIR/fort.19_2    $RUNDIR/fort.19
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
# linking fort.67 to hotstart forecast
if [ -e $nowcastDIR/PE0000/fort.67 ]; then
   ln -fs $nowcastDIR/PE0000/fort.67 $RUNDIR/fort.67
elif [ -e $nowcastDIR/PE0000/fort.68 ]; then
   ln -fs $nowcastDIR/PE0000/fort.68 $RUNDIR/fort.67
else
   fatal "Forecast S2: fort.67/8 not found in $nowcastDIR/PE0000/"
fi
# Link basin met if specified
ln -s ${forecastDIR}/fort.22      $RUNDIR/fort.22
# Defining/renaming for control options
ENSTORM="forecast"
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
hstime="on"
cd ${mainDIR}
. ${CONFIG}
#
forecastCSDATE=`cat $RUNDIR/fort.22 | awk -F"," '{print $3}' | head -1`    # is used in runday calculation
forecastenddate=`cat $RUNDIR/fort.22 | awk -F"," '{print $3}' | tail -1`   # will be used as CSDATE in stage two
#
enddate=$forecastenddate
CSDATE=`cat $workingDIR/nowCSDATE`  #CSDATE of S2 is the start time of the fort.221/2 of the 1st cycle
CONTROLOPTIONS=" --stormDir $stormDir --scriptdir $mainDIR --cst $CSDATE --endtime 0 --dt $dt --hsformat $HOTSTARTFORMAT --controltemplate $s2_INPDIR$CONTROLTEMPLATE $OUTPUTOPTIONS --name $ENSTORM --met $MET --nws $NWS --platform $platform --enddate $enddate --hstime $hstime --elevstations ${s2_INPDIR}/${s2_ELEVSTATIONS} --velstations ${s2_INPDIR}/${s2_VELSTATIONS} --metstations ${s2_INPDIR}/${s2_METSTATIONS}"
CONTROLOPTIONS="$CONTROLOPTIONS --gridname $GRIDNAME" # for run.properties
# Control options for SWAN
if [[ $WAVES = on ]]; then
   swanStart=$forecastCSDATE     # swan start time
   CONTROLOPTIONS="${CONTROLOPTIONS} --swandt $SWANDT --swantemplate ${s2_INPDIR}/${s2_swan26} --hotswan $hotswan --ID $ID --estuary "$estuary" --nddlAttribute $nddlAttribute --swanBottomFri $fricType --swanStart $swanStart"
fi
# writing fort.15 and fort.22
writeControls $CONTROLOPTIONS $RUNDIR
#
# Decomposing grid, control, and nodal attribute file
logMessage "Redirecting to HRLA directory (S2)"
logMessage "Running adcprep to partition the mesh for $NCPU compute processors."
prepFile partmesh
logMessage "Running adcprep to partition the mesh for $NCPU compute processors."
prepFile prepall
logMessage "Running adcprep to prepare new fort.15 file."
prepFile prep15
#
if [[ $WAVES = on ]]; then
   logMessage "Starting copy of wahotstart files."
   # copy the subdomain hotstart files over
   # subdomain hotstart files are always binary formatted
   PE=0
   format="%04d"
   while [ $PE -lt $NCPU ]; do
         PESTRING=`printf "$format" $PE`
         if [ -e $nowcastDIR/PE${PESTRING}/swan.67 ]; then
            cp $nowcastDIR/PE${PESTRING}/swan.67 $RUNDIR/PE${PESTRING}/swan.68 2>> ${SYSLOG}
         elif [ -e $nowcastDIR/PE${PESTRING}/swan.68 ]; then
            cp $nowcastDIR/PE${PESTRING}/swan.68 $RUNDIR/PE${PESTRING}/swan.68 2>> ${SYSLOG}
         else 
            fatal "Forecast S2: swan.67/8 not found in $nowcastDIR/PEs/"
         fi
         PE=`expr $PE + 1`
   done
   logMessage "Completed copy of subdomain hotstart files."
fi 
#
if [ $WAVES == on ]; then
   runPADCSWAN $NCPU
   logMessage "PADCSWAN job is submitted."
else
   runPADCIRC $NCPU
   logMessage "PADCIRC job is submitted."
fi
#
## Visualization  
stage=2
logMessage "Limited region estuary $ENSTORM job ended successfully. Starting postprocessing."
$mainDIR/postProc/${POSTPROCESS} $CONFIG $RUNDIR $ADVISORY $HOSTNAME $ENSTORM $CSDATE ${s2_INPDIR}/${s2_grd} $SYSLOG $stage >> ${SYSLOG} 2>&1
#
## Notifying                              
endRun=`date '+%Y%m%d%H%M%S'`
$mainDIR/src/postProc.sh $SYSLOG $CONFIG results $RUNDIR $ADVISORY $ENSTORM $startRun $endRun
