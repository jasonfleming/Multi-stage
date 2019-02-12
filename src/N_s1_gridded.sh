#!/bin/bash
#
# Stage 1
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
#                              DOWNLOAD FORT.221/222
# 
downloadBackgroundMet()
{
   workingDIR=$1
   SCRIPTDIR=$2
   BACKSITE=$3
   BACKDIR=$4
   ENSTORM=$5
   CSDATE=$6
   HSTIME=$7
   FORECASTLENGTH=$8
   FORECASTCYCLE=$9
   currentcycle=${10}
   #
   ln -fs $mainDIR/utility/PERL/Date            $workingDIR/Date
   ln -fs $mainDIR/utility/PERL/ArraySub.pm     $workingDIR/ArraySub.pm
   cd $workingDIR 2>> ${SYSLOG}
   if [[ $ENSTORM != "nowcast" ]]; then
      echo $currentcycle > currentCycle 2>> ${SYSLOG}
   fi
   newAdvisoryNum=0
   while [[ $newAdvisoryNum -lt 2 ]]; do
      OPTIONS="--rundir $workingDIR --backsite $BACKSITE --backdir $BACKDIR --enstorm $ENSTORM --csdate $CSDATE --hstime $HSTIME --forecastlength $FORECASTLENGTH --altnamdir $ALTNAMDIR --scriptdir $SCRIPTDIR --forecastcycle $FORECASTCYCLE --archivedruns ${ARCHIVEBASE}/${ARCHIVEDIR}"
      ln -fs ${SCRIPTDIR}/utility/get_nam.pl
      newAdvisoryNum=`perl get_nam.pl $OPTIONS 2>> ${SYSLOG}`
      if [[ $newAdvisoryNum -lt 2 ]]; then
         sleep 60
      fi
   done
}
#
# ---------------------------------------------------------------------------------
#
#                                 Main Body
#
. $CONFIG
hindcastDIR=${mainDIR}${ID}/hindcast
workingDIR=${mainDIR}${ID}
#
# Downloading wind and pressure files -- this specifies the rundir name
#
ENSTORM="nowcast"
#
if [ $cycle -eq 1 ]; then
   HSTIME=`$EXEDIR/hstime -f  $hindcastDIR/PE0000/fort.67` 
else
   lastDIR=`cat $workingDIR/currentCycle`
   if [ -e $mainDIR$ID/$lastDIR/nowcast/S1/PE0000/fort.67 ]; then
      HSTIME=`$EXEDIR/hstime -f  $mainDIR$ID/$lastDIR/nowcast/S1/PE0000/fort.67`    
   elif [ -e $mainDIR$ID/$lastDIR/nowcast/S1/PE0000/fort.68 ]; then
      HSTIME=`$EXEDIR/hstime -f  $mainDIR$ID/$lastDIR/nowcast/S1/PE0000/fort.68`
   else
      fatal "Nowcast S1: fort.67/8 not found in $workingDIR/$lastDIR/nowcast/S1/PE0000/"
   fi
fi
#

if [[ $MODE = FORECAST ]]; then
   logMessage "downloadBackgroundMet $workingDIR $mainDIR $BACKSITE $BACKDIR $ENSTORM $CSDATE $HSTIME $FORECASTLENGTH $FORECASTCYCLE"
   downloadBackgroundMet $workingDIR $mainDIR $BACKSITE $BACKDIR $ENSTORM $CSDATE $HSTIME $FORECASTLENGTH $FORECASTCYCLE
else
   mkdir $workingDIR/nowcast/
   mkdir $workingDIR/nowcast/S1
   RUNDIR=$workingDIR/nowcast/S1/
   ln -fs $NAM_analysis_wind  $RUNDIR/fort.222
   ln -fs $NAM_analysis_press $RUNDIR/fort.221
fi

#
echo ""  >> ${SYSLOG} 2>&1
echo ""  >> ${SYSLOG} 2>&1

if [[ $MODE = FORECAST ]]; then
   cycleDIR=`ls -l -t $workingDIR | grep '^d' | head -1 | awk '{ print $9 }'`      # Getting the latest created directory which is the current cycle
   mv $workingDIR/currentCycle $workingDIR/currentCycle.old
   echo $cycleDIR > $workingDIR/currentCycle 2>> ${SYSLOG}
   #
   NOWCASTDIR=${mainDIR}${ID}/$cycleDIR/nowcast
   mkdir ${mainDIR}${ID}/$cycleDIR/nowcast/S1
   RUNDIR=${mainDIR}${ID}/$cycleDIR/nowcast/S1
fi

#
# send out an email alerting end users that a new cycle has been issued
cd $mainDIR
$mainDIR/src/postProc.sh $SYSLOG $CONFIG newcycle $RUNDIR $cycleDIR $ENSTORM
#
logMessage "Stage 1 -- Background meteorology, nowcast in $RUNDIR"
#
VELOCITYMULTIPLIER=1
# convert met files to OWI format
if [[ $MODE = FORECAST ]]; then
   ln -fs  ${mainDIR}/utility/awip_lambert_interp.x $RUNDIR/awip_lambert_interp.x
   ln -fs  ${mainDIR}/utility/wgrib2  $RUNDIR/wgrib2
   NAMOPTIONS=" --ptFile ${mainDIR}/input/${PTFILE} --namFormat grib2 --namType $ENSTORM --awipGridNumber 218 --dataDir $NOWCASTDIR --outDir ${NOWCASTDIR}/ --velocityMultiplier $VELOCITYMULTIPLIER --scriptDir ${mainDIR} --member nam"
   logMessage "Converting NAM data to OWI format with the following options : $NAMOPTIONS"
   ln -fs ${mainDIR}/utility/NAMtoOWI.pl $RUNDIR/NAMtoOWI.pl
   cd $RUNDIR
   ln -fs $mainDIR/utility/PERL/Date            $RUNDIR/Date
   ln -fs $mainDIR/utility/PERL/ArraySub.pm     $RUNDIR/ArraySub.pm
   perl NAMtoOWI.pl $NAMOPTIONS >> ${SYSLOG} 2>&1
fi


cd $mainDIR
#
hotswan="off"
if [ $cycle -eq 1 ]; then
   ln -fs $hindcastDIR/PE0000/fort.67 $RUNDIR/fort.67
else 
   lastDIR=`cat $workingDIR/currentCycle.old`
   if [ -e $mainDIR$ID/$lastDIR/nowcast/S1/PE0000/fort.67 ]; then
      ln -fs $mainDIR$ID/$lastDIR/nowcast/S1/PE0000/fort.67  $RUNDIR/fort.67
   elif [ -e $mainDIR$ID/$lastDIR/nowcast/S1/PE0000/fort.68 ]; then
      ln -fs $mainDIR$ID/$lastDIR/nowcast/S1/PE0000/fort.68  $RUNDIR/fort.67
   else 
      fatal "Nowcast S1: fort.67/8 not found in $workingDIR$IS/$lastDIR/nowcast/S1/PE0000/"
   fi
   #
   if [[ $WAVES = on ]]; then
      hotswan="on"    # hotstarting swan if hot starting from previous cycle nowcast
  fi
fi
HSTIME=`$EXEDIR/hstime -f  $RUNDIR/fort.67`
#
logMessage "Linking input files into $RUNDIR ."
# Linking the stage one grid
ln -s ${s1_INPDIR}/${s1_grd}         $RUNDIR/fort.14
# Linking the stage one nodal attribute if specified
if [[ ! -z $s1_ndlattr && $s1_ndlattr != null ]]; then
   ln -s ${s1_INPDIR}/$s1_ndlattr  $RUNDIR/fort.13
   nddlAttribute="on"      # For bottom friction in swan
fi

if [[ $MODE = FORECAST ]]; then
   ln -fs $NOWCASTDIR/*.221  $RUNDIR/fort.221
   ln -fs $NOWCASTDIR/*.222  $RUNDIR/fort.222
fi
#
# Creating fort.15/22/26 -----------------------------------
#
if [[ $MODE = FORECAST ]]; then
   nowenddate=`ls $NOWCASTDIR | grep "NAM" | awk -F"." '{print $1}' | awk -F"_" '{print $3}' | head -1`  # is used in runday calculation
   nowCSDATE=`ls $NOWCASTDIR  | grep "NAM" | awk -F"." '{print $1}' | awk -F"_" '{print $2}' | head -1`   # will be used as CSDATE in stage two
fi
# These two parameters must be specified by user in config

enddate=$nowenddate
stormDir=$RUNDIR
CONTROLTEMPLATE=${s1_cntrl}
GRIDNAME=${s1_grd}
dt=${S1_dt}
nws='-12'
hstime="on"
#
. $CONFIG
if [[ $WAVES = on ]]; then
   if [[ $nws = 12 ]]; then
      nws=`expr $nws + 300`     # nws = 12
   else
      nws=`expr $nws - 300`     # nws = -12
   fi
   cp ${s1_INPDIR}/swaninit.template         $RUNDIR/swaninit
fi
#
#
ln -fs $mainDIR/utility/PERL/Date            $RUNDIR/Date
ln -fs $mainDIR/utility/PERL/ArraySub.pm     $RUNDIR/ArraySub.pm

#
# Creating boundary node file, containing the lat/long of the 
# center point of the nodestring defining the open boundary
# of the fine mesh at each open boundary 
# used to be specified manually as follows:
# cp $BNDIR/archive.boundary.nodes/$BNNAME  $RUNDIR/boundaryNodes
ln -fs $mainDIR/utility/buildf19/open_bn_finder.x  $RUNDIR/open_bn_finder.x
ln -fs ${s2_INPDIR}/${s2_grd}                      $RUNDIR/fort_fine.14
cd $RUNDIR
./open_bn_finder.x   # fort.142 is the output
cd -
mv $RUNDIR/fort.142 $RUNDIR/boundaryNodes

CONTROLOPTIONS=" --stormDir $stormDir --scriptdir $mainDIR --cst $CSDATE --endtime $HINDCASTLENGTH --dt $dt --hsformat $HOTSTARTFORMAT --controltemplate $s1_INPDIR$CONTROLTEMPLATE $OUTPUTOPTIONS --fort61freq "$BCFREQ" --name $ENSTORM --met $MET --nws $nws --windInterval 21600 --enddate $enddate --hstime $hstime --elevstations boundaryNodes"
CONTROLOPTIONS="$CONTROLOPTIONS --bctype $BCTYPE --stage2_spinUp $S2SPINUP --hotswan $hotswan"
CONTROLOPTIONS="$CONTROLOPTIONS --gridname $GRIDNAME" # for run.properties
# Control options for SWAN 
if [[ $WAVES = on ]]; then
   swanStart=$nowCSDATE           # start time of SWAN
   CONTROLOPTIONS="${CONTROLOPTIONS} --swandt $SWANDT --swantemplate ${s1_INPDIR}/${s1_swan26} --hotswan $hotswan --ID $ID --estuary "$estuary" --nddlAttribute $nddlAttribute --swanBottomFri $fricType --swanStart $swanStart"
fi
# writing fort.15 and fort.22
writeControls $CONTROLOPTIONS $RUNDIR
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
            if [ -e $workingDIR/$lastDIR/nowcast/S1/PE${PESTRING}/swan.68 ]; then
               cp $workingDIR/$lastDIR/nowcast/S1/PE${PESTRING}/swan.68 $RUNDIR/PE${PESTRING}/swan.68 2>> ${SYSLOG}
            elif [ -e $workingDIR/$lastDIR/nowcast/S1/PE${PESTRING}/swan.67 ]; then 
               cp $workingDIR/$lastDIR/nowcast/S1/PE${PESTRING}/swan.67 $RUNDIR/PE${PESTRING}/swan.68 2>> ${SYSLOG}
            else 
               fatal "Nowcast S1: swan.67/8 not found in $workingDIR/$lastDIR/nowcast/S1/PEs/"
            fi
            PE=`expr $PE + 1`
      done
      logMessage "SWAN subdomain hotstart files of $lastDIR have been all copied to $RUNDIR."
  fi
fi
#
cd $RUNDIR
#
if [ $WAVES == on ]; then
   logMessage "PADCSWAN job is submitted."
   runPADCSWAN $NCPU
   # Downloading GEFS
else
   logMessage "PADCIRC job is submitted."
   runPADCIRC $NCPU
fi
cd -

# Message
date_complete=`date +'%Y-%m-%d %H:%M UTC'`
logMessage "The job has completed on $date_complete"

# Cleaning, removing linked files; Perl libraries
cd $workingDIR
find . -maxdepth 1 -type l -exec unlink {} \;
cd -
~
