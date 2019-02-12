#!/bin/bash
#
# Stage 1
# Background met.
# hindcast
#
SYSLOG=$1
CONFIG=$2
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
# ------------------------------------------------------------------------
#
#                             Main Body
#
. ${CONFIG}
workingDIR=${mainDIR}${ID}
 # getting the advisory number from currentCyle file created in NOWCAST
ADVISORY=`cat $workingDIR/currentCycle`       
ADVISDIR=${mainDIR}${ID}/$ADVISORY
nowcastDIR=${mainDIR}${ID}/$ADVISORY/nowcast/S1

mkdir ${mainDIR}${ID}/$ADVISORY/forecast
mkdir ${mainDIR}${ID}/$ADVISORY/forecast/S1
#
echo ""  >> ${SYSLOG} 2>&1
echo ""  >> ${SYSLOG} 2>&1
logMessage "Stage 1 -- Tropical Cyclone, forecast in ${mainDIR}${ID}/$ADVISORY/forecast/S1"
#
ENSTORM="forecast"
HSTIME=`$EXEDIR/hstime -f   $nowcastDIR/PE0000/fort.68`
RUNDIR=${mainDIR}${ID}/$ADVISORY/forecast/S1
#
cd $ADVISDIR
#
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
   hotswan="on"    # hotstarting swan if hot starting from previous cycle nowcast
   cp ${s1_INPDIR}/swaninit.template         $RUNDIR/swaninit
fi
#
#  Setting options for downloading forecast wind and pressure
METOPTIONS=" --dir $ADVISDIR --storm $STORM --year $YEAR --coldstartdate $CSDATE --hotstartseconds $HSTIME --nws $NWS --name $ENSTORM"
if [[ ${PERCENT} != default ]]; then
   if [[ ! $ENSTORM =~ maxWindSpeedOnly ]]; then
      METOPTIONS="$METOPTIONS --percent ${PERCENT}"
   fi
fi
logMessage "Generating ADCIRC Met File (fort.22) for $ENSTORM with the following options: $METOPTIONS."
$mainDIR/utility/storm_track_gen.pl $METOPTIONS >> ${SYSLOG} 2>&1
#
if [[ $BASENWS = 19 || $BASENWS = 20 ]]; then
   # Setting ASWIP options 
   ASWIPOPTIONS=""
   if [[ ${PERCENT} != default && $ENSTORM =~ maxWindSpeedOnly ]]; then
      ASWIPOPTIONS="-X ${PERCENT}"
   fi
   if [[ ${PERCENT} != default && ${RMAX} = scaled ]]; then
      ASWIPOPTIONS="-P ${PERCENT}"
   fi
   if [[ ${RMAX} != default && ${RMAX} != scaled ]]; then
      ASWIPOPTIONS="${ASWIPOPTIONS} -R ${RMAX}"
   fi
   logMessage "Running aswip fort.22 preprocessor for $ENSTORM with the following options: $ASWIPOPTIONS."
   $EXEDIR/aswip -n $BASENWS $ASWIPOPTIONS >> ${SYSLOG} 2>&1
   if [[ -e NWS_${BASENWS}_fort.22 ]]; then
      mv fort.22 fort.22.orig 2>> ${SYSLOG}
      cp NWS_${BASENWS}_fort.22 fort.22 2>> ${SYSLOG}
      cp fort.22 $RUNDIR/fort.22  # Moving fort.22s from ADVISDIR into RUNDIR   
   fi
fi
#
cd $RUNDIR
# linking fort.67/8 to hotstart nowcast
if [ -e $nowcastDIR/PE0000/fort.68 ]; then
   ln -fs $nowcastDIR/PE0000/fort.68 $RUNDIR/fort.67
elif [ -e $nowcastDIR/PE0000/fort.67 ]; then
   ln -fs $nowcastDIR/PE0000/fort.67 $RUNDIR/fort.67
else
   fatal "Forecast S1: fort.67/8 not found in $nowcastDIR/PE0000/"
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
forecastCSDATE=`cat $RUNDIR/fort.22 | awk -F"," '{print $3}' | head -1`    # is used in runday calculation
forecastenddate=`cat $RUNDIR/fort.22 | awk -F"," '{print $3}' | tail -1`   # will be used as CSDATE in stage two
#
enddate=$forecastenddate
stormDir=$RUNDIR
CONTROLTEMPLATE=${s1_cntrl}
GRIDNAME=${s1_grd}
dt=${S1_dt}
hstime="on"
#
cd ${mainDIR}
. $CONFIG
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
mv $RUNDIR/fort.142                                $RUNDIR/boundaryNodes

# 
## Append elevation station output to boundary specification file
if [ ! -z ${s1_INPDIR}/${s1_ELEVSTATIONS} ] || [ ${s1_INPDIR}/${s1_ELEVSTATIONS} -ne "null" ]; then
   logMessage "Appending elevation station output to boundary specification file"
   cat $RUNDIR/boundaryNodes   ${s1_INPDIR}/${s1_ELEVSTATIONS} > $RUNDIR/boundaryNodes2
   mv  $RUNDIR/boundaryNodes2  $RUNDIR/boundaryNodes
fi
#
CONTROLOPTIONS=" --stormDir $stormDir --scriptdir $mainDIR --cst $CSDATE --endtime $HINDCASTLENGTH --dt $dt --hsformat $HOTSTARTFORMAT --controltemplate $s1_INPDIR$CONTROLTEMPLATE $OUTPUTOPTIONS --fort61freq "$BCFREQ" --name $ENSTORM --met $MET --nws $NWS --windInterval 10800 --enddate $enddate --hstime $hstime --elevstations boundaryNodes --velstations ${s1_INPDIR}/${s1_VELSTATIONS} --metstations ${s1_INPDIR}/${s1_METSTATIONS}"
CONTROLOPTIONS="$CONTROLOPTIONS --gridname $GRIDNAME" # for run.properties
if [[ $WAVES = on ]]; then
   swanStart=$forecastCSDATE     # swan start time
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
if [[ $WAVES = on ]]; then
   logMessage "Starting copy of hotstart files."
   # copy the subdomain hotstart files over
   # subdomain hotstart files are always binary formatted
   PE=0
   format="%04d"
   while [ $PE -lt $NCPU ]; do
         PESTRING=`printf "$format" $PE`
         if [ -e $nowcastDIR/PE${PESTRING}/swan.68 ]; then
            cp $nowcastDIR/PE${PESTRING}/swan.68 $RUNDIR/PE${PESTRING}/swan.68 2>> ${SYSLOG}
         elif [ -e $nowcastDIR/PE${PESTRING}/swan.67 ]; then
            cp $nowcastDIR/PE${PESTRING}/swan.67 $RUNDIR/PE${PESTRING}/swan.68 2>> ${SYSLOG}
         else
             fatal "Forecast S1: swan.67/8 not found in  $nowcastDIR/PEs"
         fi
         PE=`expr $PE + 1`
   done
   logMessage "Completed copy of subdomain hotstart files."
fi 
#
cd $RUNDIR
if [ $WAVES == on ]; then
   runPADCSWAN $NCPU
   logMessage "PADCSWAN job is submitted."
else
   runPADCIRC $NCPU
   logMessage "PADCIRC job is submitted."
fi
cd -
# Cleaning, removing linked files; Perl libraries + NAMtoOWI.pl + get_NAM.pl
cd $workingDIR
find . -maxdepth 1 -type l -exec unlink {} \;
cd $mainDIR
#
## Post processing
logMessage "Large-scale $ENSTORM job ended successfully. Starting postprocessing."
$mainDIR/postProc/${POSTPROCESS} $CONFIG $RUNDIR $ADVISORY $HOSTNAME $ENSTORM $CSDATE ${s1_INPDIR}/${s1_grd} $SYSLOG 1 >> ${SYSLOG} 2>&1
