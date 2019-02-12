#!/bin/bash
#
# Stage 2
# Gridded meteorology
# Forecast for small-scale fine mesh
#
SYSLOG=$1
CONFIG=$2
startRun=$3
member=$4
#
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
cycleDIR=`cat $mainDIR$ID/currentCycle`
nowcastDIR=$mainDIR$ID/$cycleDIR/nowcast/S2       # of stage two
forecastDIR=$mainDIR$ID/$cycleDIR/$member/S1      # of stage one

#
mkdir $mainDIR$ID/$cycleDIR/$member/S2
RUNDIR=$mainDIR$ID/$cycleDIR/$member/S2
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
#if [[ $MODE = FORECAST ]]; then
if [[ $member = nam ]]; then
   ln -s ${forecastDIR}/fort.221                       $RUNDIR/fort.221
   ln -s ${forecastDIR}/fort.222                       $RUNDIR/fort.222
elif [[ $member = GEFSmean ]]; then
     cp  ${mainDIR}/GEFS/uv_IRL/fort.221_mean_IRL      $RUNDIR/fort.221
     cp  ${mainDIR}/GEFS/uv_IRL/fort.222_mean_IRL      $RUNDIR/fort.222
elif [[ $member = GEFSmeanPstd ]]; then
     cp  ${mainDIR}/GEFS/uv_IRL/fort.221_meanPstd_IRL  $RUNDIR/fort.221
     cp  ${mainDIR}/GEFS/uv_IRL/fort.222_meanPstd_IRL  $RUNDIR/fort.222
elif [[ $member = GEFSmeanMstd ]]; then
     cp  ${mainDIR}/GEFS/uv_IRL/fort.221_meanMstd_IRL  $RUNDIR/fort.221
     cp  ${mainDIR}/GEFS/uv_IRL/fort.222_meanMstd_IRL  $RUNDIR/fort.222
elif [[ $member = SREFmean ]]; then
     cp ${mainDIR}/SREF/UVP/sref_mean.221              $RUNDIR/fort.221
     cp ${mainDIR}/SREF/UVP/sref_mean.222              $RUNDIR/fort.222
elif [[ $member = SREFmeanPstd ]]; then
     cp ${mainDIR}/SREF/UVP/sref_Pstd.221              $RUNDIR/fort.221
     cp ${mainDIR}/SREF/UVP/sref_Pstd.222              $RUNDIR/fort.222
elif [[ $member = SREFmeanMstd ]]; then
     cp ${mainDIR}/SREF/UVP/sref_Mstd.221              $RUNDIR/fort.221
     cp ${mainDIR}/SREF/UVP/sref_Mstd.222              $RUNDIR/fort.222
fi

# Setting up some paramters
ENSTORM=${member}
stormDir=$RUNDIR
CONTROLTEMPLATE=${s2_cntrl}
GRIDNAME=${s2_grd}
dt=${S2_dt}
nws='-12'
tides="off"
hstime="on"

# Activating waves
if [[ $WAVES = on ]]; then
   if [[ $nws = 12 ]]; then
      nws=`expr $nws + 300`     # nws = 12
   else
      nws=`expr $nws - 300`     # nws = -12
   fi
   hotswan="on"
   cp ${s2_INPDIR}/swaninit.template         $RUNDIR/swaninit
fi 
cd ${mainDIR}
. ${CONFIG}

# Setting up the start and end times 
forecastenddate=`ls $mainDIR$ID/$cycleDIR/namforecast | grep "NAM" | awk -F"." '{print $1}' | awk -F"_" '{print $3}' | head -1`  # is used in runday calculation
forecastCSDATE=`ls $mainDIR$ID/$cycleDIR/namforecast | grep "NAM" | awk -F"." '{print $1}' | awk -F"_" '{print $2}' | head -1`   # will be used as CSDATE in stage two

enddate=$forecastenddate
CSDATE=`cat $workingDIR/nowCSDATE`  #CSDATE of S2 is the start time of the fort.221/2 of the 1st cycle

# Create fort.15 for NAM and make a copy of this for GEFS runs
if [[ $member = nam ]]; then
   CONTROLOPTIONS=" --stormDir $stormDir --scriptdir $mainDIR --cst $CSDATE --endtime 0 --dt $dt --hsformat $HOTSTARTFORMAT --controltemplate $s2_INPDIR$CONTROLTEMPLATE $OUTPUTOPTIONS --name $ENSTORM --met $MET --nws $nws --windInterval 10800 --platform $platform --enddate $enddate --hstime $hstime --elevstations ${s2_INPDIR}/${s2_ELEVSTATIONS} --velstations ${s2_INPDIR}/${s2_VELSTATIONS} --metstations ${s2_INPDIR}/${s2_METSTATIONS}"
   CONTROLOPTIONS="$CONTROLOPTIONS --gridname $GRIDNAME" # for run.properties
   # Control options for SWAN
   if [[ $WAVES = on ]]; then
      swanStart=$forecastCSDATE     # swan start time
      CONTROLOPTIONS="${CONTROLOPTIONS} --swandt $SWANDT --swantemplate ${s2_INPDIR}/${s2_swan26} --hotswan $hotswan --ID $ID --estuary "$estuary" --nddlAttribute $nddlAttribute --swanBottomFri $fricType --swanStart $swanStart"
   fi
   # writing fort.15 and fort.22
   writeControls $CONTROLOPTIONS $RUNDIR
else
   cp ${mainDIR}${ID}/$cycleDIR/nam/S2/fort.15  $RUNDIR/fort.15
   cp ${mainDIR}${ID}/$cycleDIR/nam/S2/fort.26  $RUNDIR/fort.26
   cp ${mainDIR}${ID}/$cycleDIR/nam/S2/fort.22  $RUNDIR/fort.22
   
   # We still need PERL libraries for station_transpose.pl
   ln -fs $mainDIR/utility/PERL/Date            $RUNDIR/Date
   ln -fs $mainDIR/utility/PERL/ArraySub.pm     $RUNDIR/ArraySub.pm
fi

# Decomposing grid, control, and nodal attribute file
logMessage "Redirecting to HRLA directory (S2)"
logMessage "Running adcprep to partition the mesh for $NCPU compute processors."
prepFile partmesh
logMessage "Running adcprep to partition the mesh for $NCPU compute processors."
prepFile prepall
logMessage "Running adcprep to prepare new fort.15 file."
prepFile prep15

logMessage "Starting copy of SWAN hotstart files."
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
logMessage "SWAN subdomain hotstart files of $lastDIR have been all copied to $RUNDIR."
#
if [ $WAVES == on ]; then
   runPADCSWAN $NCPU
   logMessage "PADCSWAN job is submitted."
else
   runPADCIRC $NCPU
   logMessage "PADCIRC job is submitted."
fi

# Message
date_complete=`date +'%Y-%m-%d %H:%M UTC'`
logMessage "The job has completed on $date_complete"

# Visualization  
stage=2
logMessage "Small-scale, fine mesh run for $ENSTORM job ended successfully. Starting postprocessing ..."

########################## temp: developing
# empty option ruins the plotting processes
if [[ $MODE = HINDCAST ]]; then
   cycleDIR="empty"
fi
###########################################

# To avoid getting the CSDATE of stage 1
# $mainDIR/postProc/${POSTPROCESS} $CONFIG $RUNDIR $cycleDIR $HOSTNAME $ENSTORM $CSDATE ${s2_INPDIR}/${s2_grd} $SYSLOG $stage >> ${SYSLOG} 2>&1
startDATE=`cat $workingDIR/nowCSDATE`  
$mainDIR/postProc/${POSTPROCESS} $CONFIG $RUNDIR $cycleDIR $HOSTNAME $ENSTORM $startDATE ${s2_INPDIR}/${s2_grd} $SYSLOG $stage >> ${SYSLOG} 2>&1

# Creating validation plots and calculating wall-clock time and notify the user                   
if [[ $member = SREFmeanMstd ]]; then
   cd $mainDIR
   . $CONFIG
   endRun=`date '+%Y%m%d%H%M%S'`
   $mainDIR/src/postProc.sh $SYSLOG $CONFIG results $RUNDIR $cycleDIR $ENSTORM $startRun $endRun
fi
