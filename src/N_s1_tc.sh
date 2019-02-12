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
# ---------------------------------------------------------------------------------
# subroutine that calls an external script over and over until it
# pulls down a new advisory (then it returns)
downloadCycloneData()
{   STORM=$1
    YEAR=$2
    RUNDIR=$3
    SCRIPTDIR=$4
    OLDADVISDIR=$5
    TRIGGER=$6
    ADVISORY=$7
    FTPSITE=$8
    RSSSITE=$9
    FDIR=${10}
    HDIR=${11}
#    activity_indicator "Checking remote site for new advisory..." &
    echo "Checking remote site for new advisory..."
    cd $workingDIR 2>> ${SYSLOG}
    newAdvisory=false
    newAdvisoryNum=null
    forecastFileName=al${STORM}${YEAR}.fst
    hindcastFileName=bal${STORM}${YEAR}.dat
    OPTIONS="--storm $STORM --year $YEAR --ftpsite $FTPSITE --fdir $FDIR --hdir $HDIR --rsssite $RSSSITE --trigger $TRIGGER --adv $ADVISORY"
    logMessage "Options for get_atcf.pl are as follows : $OPTIONS"
    if [ "$START" = coldstart ]; then
       logMessage "Downloading initial hindcast/forecast."
    else
       logMessage "Checking remote site for new advisory..."
    fi
    while [ $newAdvisory = false ]; do
       if [[ $TRIGGER != "atcf" ]]; then
          newAdvisoryNum=`perl $SCRIPTDIR/get_atcf.pl $OPTIONS 2>> $SYSLOG`
       fi
       # check to see if we have a new one, and if so, determine the
       # new advisory number correctly
       case $TRIGGER in
       "atcf") 
          # if the forecast is already in ATCF format, then simply copy it 
          # to the run directory
          cp $HDIR/$hindcastFileName . 2>> ${SYSLOG}
          cp $FDIR/$forecastFileName . 2>> ${SYSLOG}
          linkTarget=`readlink $FDIR/$forecastFileName`
          # assume the advisory number is the first two characters in the
          # symbolic link target of the forecast file name
          newAdvisoryNum=${linkTarget:0:2}
          if [[ $newAdvisoryNum -gt $ADVISORY ]]; then 
             newAdvisory="true" 
          else 
             newAdvisory="false" 
          fi
          ;;
       "ftp")
          if ! diff $OLDADVISDIR/$forecastFileName ./$forecastFileName > /dev/null 2>> ${SYSLOG}; then
             echo "thereeee is difference"
             # forecasts from NHC ftp site do not have advisory number
             newAdvisoryNum=`printf "%02d" $[$ADVISORY + 1]`
             newAdvisory="true"
          fi
          ;;
       "rss" | "rssembedded" )
          # if there was a new advisory, the get_atcf.pl script
          # would have returned the advisory number in stdout
          if [[ ! -z $newAdvisoryNum && $newAdvisoryNum != null ]]; then
             newAdvisory="true"
             if [ -e $forecastFileName ]; then
                mv $forecastFileName $forecastFileName.ftp 2>> $SYSLOG
             fi
          fi
          ;;
       *)
          fatal "Invalid 'TRIGGER' type: '$TRIGGER'; must be ftp, rss or rssembedded."
          ;;
       esac
       if [ $cycle  = 1 ]; then
          if [ $TRIGGER = ftp ]; then
             newAdvisoryNum=$ADVISORY
          fi
          newAdvisory="true"
       fi
       if [[ $newAdvisory = false ]]; then
          sleep 60 # we are hotstarting, the advisory is same as last one
       fi
    done
    logMessage "New forecast detected."
    cd $workingDIR
    mv currentCycle currentCycle.old
    echo $newAdvisoryNum > currentCycle  
    if [[ $TRIGGER = rss || $TRIGGER = rssembedded ]]; then
       perl ${SCRIPTDIR}/nhc_advisory_bot.pl --input ${forecastFileName}.html --output $forecastFileName  >> ${SYSLOG} 2>&1
    fi
    if [[ $FTPSITE = filesystem ]]; then
       cp $HDIR/$hindcastFileName $hindcastFileName 2>> ${SYSLOG}
    fi
}
#
# ---------------------------------------------------------------------------------
#
#                                 Main Body
#
. $CONFIG
echo "" >> ${SYSLOG} 2>&1
logMessage "Stage 1 -- Tropical Cyclone, nowcast in $RUNDIR"
hindcastDIR=${mainDIR}${ID}/hindcast
workingDIR=${mainDIR}${ID}
ENSTORM="nowcast"
#
# Setting NWS
#
cd $workingDIR
BASENWS=20
if [[ $VORTEXMODEL = ASYMMETRIC ]]; then
   BASENWS=19
fi
if [[ $VORTEXMODEL = SYMMETRIC ]]; then
   BASENWS=8
fi
NWS=$BASENWS
if [[ $WAVES = on ]]; then
   NWS=`expr $BASENWS + 300`
fi
#
# Getting the Advisory number from previous run
#
if [ $cycle -eq 1 ]; then
   ADVISORY=$STARTADVISORYNUM                # Previous run is hindcast
else
   ADVISORY=`cat $workingDIR/currentCycle`   # Previous run is forecast
fi
#
# Downloading wind and pressure files
OLDADVIS=`cat $workingDIR/currentCycle`  # will be renamed to currentCycle.old by downloadCycloneData
OLDADVISDIR=$workingDIR/$OLDADVIS
downloadCycloneData $STORM $YEAR $workingDIR $mainDIR/utility $OLDADVISDIR $TRIGGER $ADVISORY $FTPSITE $RSSSITE $FDIR $HDIR 
LASTADVISORYNUM=$ADVISORY
# pull the latest advisory number from the currentCycle that has been re-written by downloadCycleData()
ADVISORY=`cat $workingDIR/currentCycle`
#
# Setting and creating run directories
ADVISDIR=$workingDIR/${ADVISORY}
if [ ! -d $ADVISDIR ]; then
   mkdir $ADVISDIR 2>> ${SYSLOG}
fi
NOWCASTDIR=$ADVISDIR/$ENSTORM
if [ ! -d $NOWCASTDIR ]; then
   mkdir $NOWCASTDIR 2>> ${SYSLOG}
fi
mkdir ${NOWCASTDIR}/S1
RUNDIR=${NOWCASTDIR}/S1
allMessage "$START Storm $STORM advisory $ADVISORY in $YEAR"
#
# move raw ATCF files into advisory directory
mv *.fst *.dat *.xml *.html $ADVISDIR 2>> ${SYSLOG}
#
#
# Getting hotstart time from previous run
if [ $cycle -eq 1 ]; then  # Previous run is hindcast
   HSTIME=`$EXEDIR/hstime -f  $hindcastDIR/PE0000/fort.67`
else                       # Previous run is ofrecast
   lastDIR=`cat $workingDIR/currentCycle.old`
   if [ -e $mainDIR$ID/$lastDIR/nowcast/S1/PE0000/fort.67 ]; then
      HSTIME=`$EXEDIR/hstime -f  $mainDIR$ID/$lastDIR/nowcast/S1/PE0000/fort.67`
   elif [ -e $mainDIR$ID/$lastDIR/nowcast/S1/PE0000/fort.68 ]; then
      HSTIME=`$EXEDIR/hstime -f  $mainDIR$ID/$lastDIR/nowcast/S1/PE0000/fort.68`
   else
      fatal "Nowcast S1: fort.67/8 not found in $workingDIR/$lastDIR/nowcast/S1/PE0000/"
   fi
fi
#
# Creating fort.22 ---------------
cd $ADVISORY
ln -fs $mainDIR/utility/PERL/Date            $ADVISDIR/Date
ln -fs $mainDIR/utility/PERL/ArraySub.pm     $ADVISDIR/ArraySub.pm
logMessage "Generating ADCIRC Met File (fort.22) for nowcast with the following options: $METOPTIONS."
METOPTIONS="--dir $ADVISDIR --storm $STORM --year $YEAR --name $ENSTORM --nws $NWS --hotstartseconds $HSTIME --coldstartdate $CSDATE"
${mainDIR}/utility/storm_track_gen.pl $METOPTIONS >> ${SYSLOG} 2>&1
#
$EXEDIR/aswip -n $BASENWS >> ${SYSLOG} 2>&1
if [[ -e NWS_${BASENWS}_fort.22 ]]; then
  mv fort.22 fort.22.orig >> ${SYSLOG} 2>&1
  cp NWS_${BASENWS}_fort.22 fort.22 >> ${SYSLOG} 2>&1
  cp fort.22 $RUNDIR/fort.22  # Moving fort.22s from ADVISDIR into RUNDIR
fi
# --------------------------------
#
# send out an email alerting end users that a new cycle has been issued
cd $mainDIR
$mainDIR/src/postProc.sh $SYSLOG $CONFIG newAdv $RUNDIR $ADVISORY $ENSTORM
# --------------------------------
#
cd $RUNDIR
ln -fs $mainDIR/utility/PERL/Date            $RUNDIR/Date
ln -fs $mainDIR/utility/PERL/ArraySub.pm     $RUNDIR/ArraySub.pm
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
#
if [[ $WAVES = on ]]; then
   cp ${s1_INPDIR}/swaninit.template         $RUNDIR/swaninit
fi
#
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
#
# Creating fort.15/22/26 -----------------------------------
#
nowCSDATE=`cat $RUNDIR/fort.22 | awk -F"," '{print $3}' | head -1`  # is used in runday calculation
nowenddate=`cat $RUNDIR/fort.22 | awk -F"," '{print $3}' | head -2 | tail -1`   # will be used as CSDATE in stage two
enddate=$nowenddate
stormDir=$RUNDIR
CONTROLTEMPLATE=${s1_cntrl}
GRIDNAME=${s1_grd}
dt=${S1_dt}
hstime="on"
#
. $CONFIG

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

CONTROLOPTIONS=" --stormDir $stormDir --scriptdir $mainDIR --cst $CSDATE --endtime $HINDCASTLENGTH --dt $dt --hsformat $HOTSTARTFORMAT --controltemplate $s1_INPDIR$CONTROLTEMPLATE $OUTPUTOPTIONS --fort61freq "$BCFREQ" --name $ENSTORM --met $MET --nws $NWS --windInterval 21600 --enddate $enddate --hstime $hstime --elevstations boundaryNodes"
CONTROLOPTIONS="$CONTROLOPTIONS --bctype $BCTYPE --stage2_spinUp $S2SPINUP --hotswan $hotswan"
CONTROLOPTIONS="$CONTROLOPTIONS --gridname $GRIDNAME" # for run.properties
# Control options for SWAN 
if [[ $WAVES = on ]]; then
   swanStart=$nowCSDATE           # start time of SWAN
   CONTROLOPTIONS="${CONTROLOPTIONS} --swandt $SWANDT --swantemplate ${s1_INPDIR}/${s1_swan26} --hotswan $hotswan --ID $ID --estuary "$estuary" --nddlAttribute $nddlAttribute --swanBottomFri $fricType --swanStart $swanStart"
fi
#
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
      logMessage "Completed copy of subdomain hotstart files."
  fi
fi
#
cd $RUNDIR
#
if [ $WAVES == on ]; then
   logMessage "PADCSWAN job is submitted."
   runPADCSWAN $NCPU
else
   logMessage "PADCIRC job is submitted."
   runPADCIRC $NCPU
fi
cd -
# Cleaning, removing linked files; Perl libraries
cd $workingDIR
find . -maxdepth 1 -type l -exec unlink {} \;
cd -
~
