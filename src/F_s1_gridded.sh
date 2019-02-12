#!/bin/bash
#
# Stage 1
# Gridded meteorology
# Forecast for large-scale coarse mesh
#
SYSLOG=$1
CONFIG=$2
startrun=$3
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
# ---------------------------------------------------------------------------------
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
#   if [[ $ENSTORM != "nowcast" ]]; then
#      echo $currentcycle > currentCycle 2>> ${SYSLOG}
#   fi
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
# ------------------------------------------------------------------------
#
#                             Main Body
#
. ${CONFIG}
workingDIR=${mainDIR}${ID}
cycleDIR=`cat $workingDIR/currentCycle`       # getting the cycleDIR name from currentCyle file created in NOWCAST
nowcastDIR=${mainDIR}${ID}/$cycleDIR/nowcast/S1
hindcastDIR=${mainDIR}${ID}/hindcast
#
mkdir ${mainDIR}${ID}/$cycleDIR/$member
mkdir ${mainDIR}${ID}/$cycleDIR/$member/S1
#
echo ""  >> ${SYSLOG} 2>&1
echo ""  >> ${SYSLOG} 2>&1
logMessage "Stage 1 -- Background meteorology, member $member, in ${mainDIR}${ID}/$cycleDIR/$member/S1"
#
RUNDIR=${mainDIR}${ID}/$cycleDIR/$member/S1
#
#
# Downloading wind and pressure files -----------------------------------
#
#ENSTORM="forecast"
ENSTORM=${member}
FORECASTDIR=${mainDIR}${ID}/$cycleDIR/namforecast

HSTIME=`$EXEDIR/hstime -f   $nowcastDIR/PE0000/fort.68`

# Creating wind/press for NAM and linking already created wind/press of GEFS and SREF (by separate modules:GEFS, SREF)
if [[ $member = nam ]]; then
   logMessage "downloadBackgroundMet $workingDIR $mainDIR $BACKSITE $BACKDIR $ENSTORM $CSDATE $HSTIME $FORECASTLENGTH $FORECASTCYCLE $cycleDIR"
   downloadBackgroundMet $workingDIR $mainDIR $BACKSITE $BACKDIR $ENSTORM $CSDATE $HSTIME $FORECASTLENGTH $FORECASTCYCLE $cycleDIR
elif [[ $member = GEFSmean ]]; then 
     cp ${mainDIR}/GEFS/uv_ec_large/fort.221_mean_ec_large      $RUNDIR/fort.221 
     cp ${mainDIR}/GEFS/uv_ec_large/fort.222_mean_ec_large      $RUNDIR/fort.222
elif [[ $member = GEFSmeanPstd ]]; then
     cp ${mainDIR}/GEFS/uv_ec_large/fort.221_meanPstd_ec_large  $RUNDIR/fort.221
     cp ${mainDIR}/GEFS/uv_ec_large/fort.222_meanPstd_ec_large  $RUNDIR/fort.222
elif [[ $member = GEFSmeanMstd ]]; then
     cp ${mainDIR}/GEFS/uv_ec_large/fort.221_meanMstd_ec_large  $RUNDIR/fort.221
     cp ${mainDIR}/GEFS/uv_ec_large/fort.222_meanMstd_ec_large  $RUNDIR/fort.222
elif [[ $member = SREFmean ]]; then
     cp ${mainDIR}/SREF/UVP/sref_mean.221                       $RUNDIR/fort.221
     cp ${mainDIR}/SREF/UVP/sref_mean.222                       $RUNDIR/fort.222
elif [[ $member = SREFmeanPstd ]]; then
     cp ${mainDIR}/SREF/UVP/sref_Pstd.221                       $RUNDIR/fort.221
     cp ${mainDIR}/SREF/UVP/sref_Pstd.222                       $RUNDIR/fort.222
elif [[ $member = SREFmeanMstd ]]; then
     cp ${mainDIR}/SREF/UVP/sref_Mstd.221                       $RUNDIR/fort.221
     cp ${mainDIR}/SREF/UVP/sref_Mstd.222                       $RUNDIR/fort.222
fi

# Wind speed multiplier
VELOCITYMULTIPLIER=1

# Convert MET files to OWI format: this is applicable for real-time forecast
if [[ $member = nam ]]; then
   ln -fs  ${mainDIR}/utility/awip_lambert_interp.x $workingDIR/awip_lambert_interp.x
   ln -fs  ${mainDIR}/utility/wgrib2  $workingDIR/wgrib2
   NAMOPTIONS=" --ptFile ${mainDIR}/input/${PTFILE} --namFormat grib2 --namType $ENSTORM --awipGridNumber 218 --dataDir $FORECASTDIR --outDir ${FORECASTDIR}/ --velocityMultiplier $VELOCITYMULTIPLIER --scriptDir ${mainDIR} --member nam"
   logMessage "Converting NAM data to OWI format with the following options : $NAMOPTIONS"
   ln -fs ${mainDIR}/utility/NAMtoOWI.pl $workingDIR/NAMtoOWI.pl
   #
   ln -fs $mainDIR/utility/PERL/Date            $workingDIR/Date
   ln -fs $mainDIR/utility/PERL/ArraySub.pm     $workingDIR/ArraySub.pm
   perl NAMtoOWI.pl $NAMOPTIONS >> ${SYSLOG} 2>&1
fi

# Redirect to run directory
cd $RUNDIR

# linking fort.67/8 to hotstart nowcast
# FORECAST starts from a nowcast
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

# Linking the wind/press generated by gen_nam.pl  
if [[ $member = nam ]]; then
   ln -fs $FORECASTDIR/*.221  $RUNDIR/fort.221
   ln -fs $FORECASTDIR/*.222  $RUNDIR/fort.222
fi

# Creating fort.15/22/26 
forecastenddate=`ls $FORECASTDIR | grep "NAM" | awk -F"." '{print $1}' | awk -F"_" '{print $3}' | head -1`  # is used in runday calculation
forecastCSDATE=`ls $FORECASTDIR | grep "NAM" | awk -F"." '{print $1}' | awk -F"_" '{print $2}' | head -1`   # will be used as CSDATE in stage two

# Setting up some parameters 
enddate=$forecastenddate
stormDir=$RUNDIR
CONTROLTEMPLATE=${s1_cntrl}
GRIDNAME=${s1_grd}
dt=${S1_dt}
nws='-12'
hstime="on"

# Activating waves 
if [[ $WAVES = on ]]; then
   if [[ $nws = 12 ]]; then
      nws=`expr $nws + 300`     # nws = 12
   else
      nws=`expr $nws - 300`     # nws = -12
   fi
   # Hindcast start from hindcast (need to work on names), forecast starts from nowcast. So hotswan is on for real-time application
   hotswan="on"    # hotstarting swan if hot starting from previous cycle nowcast
   cp ${s1_INPDIR}/swaninit.template         $RUNDIR/swaninit
fi
#
cd ${mainDIR}
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
	
## Append elevation station output to boundary specification file
if [ ! -z ${s1_INPDIR}/${s1_ELEVSTATIONS} ] || [ ${s1_INPDIR}/${s1_ELEVSTATIONS} -ne "null" ]; then
   logMessage "Appending elevation station output to boundary specification file"
   cat $RUNDIR/boundaryNodes   ${s1_INPDIR}/${s1_ELEVSTATIONS} > $RUNDIR/boundaryNodes2
   mv  $RUNDIR/boundaryNodes2  $RUNDIR/boundaryNodes 
fi

# Create fort.15 for NAM and make a copy of this for GEFS and SREF runs
if [[ $member = nam ]]; then
   CONTROLOPTIONS=" --stormDir $stormDir --scriptdir $mainDIR --cst $CSDATE --endtime $HINDCASTLENGTH --dt $dt --hsformat $HOTSTARTFORMAT --controltemplate $s1_INPDIR$CONTROLTEMPLATE $OUTPUTOPTIONS --fort61freq "$BCFREQ" --name $ENSTORM --met $MET --nws $nws --windInterval 10800 --enddate $enddate --hstime $hstime --elevstations boundaryNodes --velstations ${s1_INPDIR}/${s1_VELSTATIONS} --metstations ${s1_INPDIR}/${s1_METSTATIONS}"
  CONTROLOPTIONS="$CONTROLOPTIONS --gridname $GRIDNAME" # for run.properties
   if [[ $WAVES = on ]]; then
      swanStart=$forecastCSDATE     # swan start time
      CONTROLOPTIONS="${CONTROLOPTIONS} --swandt $SWANDT --swantemplate ${s1_INPDIR}/${s1_swan26} --hotswan $hotswan --ID $ID --estuary "$estuary" --nddlAttribute $nddlAttribute --swanBottomFri $fricType --swanStart $swanStart"
   fi
   # writing fort.15 and fort.22
   writeControls $CONTROLOPTIONS $RUNDIR
else 
   cp ${mainDIR}${ID}/$cycleDIR/nam/S1/fort.15  $RUNDIR/fort.15
   cp ${mainDIR}${ID}/$cycleDIR/nam/S1/fort.26  $RUNDIR/fort.26
   cp ${mainDIR}${ID}/$cycleDIR/nam/S1/fort.22  $RUNDIR/fort.22
   
   # We still need these for creating plots
   #
   ln -fs $mainDIR/utility/PERL/Date            $RUNDIR/Date
   ln -fs $mainDIR/utility/PERL/ArraySub.pm     $RUNDIR/ArraySub.pm
fi                                   

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
logMessage "SWAN subdomain hotstart files of $lastDIR have been all copied to $RUNDIR."
fi 

# Submitting jobs
cd $RUNDIR
if [ $WAVES == on ]; then
   runPADCSWAN $NCPU
   logMessage "PADCSWAN job is submitted."
else
   runPADCIRC $NCPU
   logMessage "PADCIRC job is submitted."
fi
cd -

# Message
date_complete=`date +'%Y-%m-%d %H:%M UTC'`
logMessage "The job has completed on $date_complete"

# Creating swan.61 (for now; at Sebastian CPRG gauge)
logMessage "Creating swan.61 by calling /postProc/latLong.pull.n3.x"

# Linking
cp     ${s1_INPDIR}/${s1_WAVESTATION}       $RUNDIR/${s1_WAVESTATION}
ln -fs $mainDIR/postProc/latLong.pull.n3.x  $RUNDIR/latLong.pull.n3.x

# Extracting
cd $RUNDIR
./latLong.pull.n3.x ${s1_WAVESTATION} fort.14 swan_HS.63
cd - 

# Cleaning, removing linked files; Perl libraries + NAMtoOWI.pl + get_NAM.pl
cd $workingDIR
find . -maxdepth 1 -type l -exec unlink {} \;
cd $mainDIR

# Post processing
logMessage "Large-scale $ENSTORM job for member $member ended successfully. Starting postprocessing."
$mainDIR/postProc/${POSTPROCESS} $CONFIG $RUNDIR $cycleDIR $HOSTNAME $ENSTORM $CSDATE ${s1_INPDIR}/${s1_grd} $SYSLOG 1 >> ${SYSLOG} 2>&1
