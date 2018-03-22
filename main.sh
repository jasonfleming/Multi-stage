#!/bin/bash
# --------------------------------------------------------------------
#
# This script is the core program of the Multi-stage tool.
# It carries out each step of the modeling process by reading the config
# file and calling the auxillary components,
#  usage:
#  ./main.sh -c config.sh
# 
# --------------------------------------------------------------------------
# Copyright(C) 2018 Florida Institute of Technology
# Copyright(C) 2018 Peyman Taeb & Robert J Weaver
#
# This program is prepared as a part of the Multi-stage tool.
# The Multi-stage tool is an open-source software available to run, study,
# change, distribute under the terms and conditions of the latest version
# of the GNU General Public License (GPLv3) as published in 2007.
#
# Although the Multi-stage tool is developed with careful considerations
# with the aim of usefulness and helpfulness, we do not make any warranty
# express or implied, do not assume any responsibility for the accuracy,
# completeness, or usefulness of any components and outcomes.
#
# The terms and conditions of the GPL are available to anybody receiving
# a copy of the Multi-stage tool. It can be also found in
# <http://www.gnu.org/licenses/gpl.html>.
#
# --------------------------------------------------------------------------
#
echoHelp()
{ clear
  echo "@@@ Help @@@"
  echo "Usage:"
  echo " bash %$0 [-c /fullpath/of/config.sh] "
  echo
  echo "Options:"
  echo "-c : set location of configuration file"
  echo "-h : show help"
  exit;
}
#                   
while getopts "c:h" optname; do    #<- first getopts for SCRIPTDIR
  case $optname in
    c) CONFIG=${OPTARG}
       if [[ ! -e $CONFIG ]]; then
          echo "ERROR: $CONFIG does not exist."
          exit $EXIT_NOT_OK
       fi
      ;;
    h) echoHelp     
      ;;
  esac
done
#
# Read config file to find the path to $SCRIPTDIR
. ${CONFIG}
# name amst log file 
STARTDATETIME=`date +'%Y-%h-%d-T%H:%M'`
SYSLOG=`pwd`/multiStage-${STARTDATETIME}.log
#
# logMessage subroutine (containing date) ---------------
logMessage() 
{ DATETIME=`date +'%Y-%h-%d-T%H:%M:%S'`
  MSG="[${DATETIME}] INFO: $@"
  echo ${MSG} >> ${SYSLOG}
}
# log an error message, execution halts -----------------
fatal()
{ DATETIME=`date +'%Y-%h-%d-T%H:%M:%S'`
  MSG="[${DATETIME}] FATAL ERROR: $@"
  echo ${MSG} >> ${SYSLOG}
  if [[ $EMAILNOTIFY = yes || $EMAILNOTIFY = YES ]]; then
     cat ${SYSLOG} | mail -s "Fatal Error for PROCID ($$)"
  fi
  echo ${MSG} # send to console
  exit ${EXIT_NOT_OK}
}
# -------------------------------------------------------
CRRNTDIR=$(pwd)
. ${CONFIG}
#
# Creating run directories for each stage.
# Tropical cyclone ==> Two directories created for stage one: 1) tide only, 2)tide&met.
# 
# Grided meteorological forcing ==> Once directory created for S1: 1)tide&Met 
# By specifying blank snaps in fort.22, no need to stop the tide only simulation, and re-run
# with tide and met.
#
 logMessage "Creating run directories under ${SCRDIR}/${ID}" 
 mkdir $ID
 mkdir $ID/S1
 mkdir $ID/S1/TideMetSpinUp
 mkdir $ID/S2/
 if [ "$MET" == "NHC" ]; then
      mkdir $ID/S1/TideSpinUp
      mkdir $ID/S2/TideSpinUp
      mkdir $ID/S2/TideMetSpinUp
 else 
      mkdir $ID/S2/TideMetSpinUp
 fi
 . $CONFIG
#
# ---------------------------------------------------------------------------
#
# subroutine to check for the existence of required directories
# that have been specified in config.sh
checkDirExistence()
{ DIR=$1
  TYPE=$2
  # In case the directory is not specified the $TYPE is assigned to $DIR, and
  # the $TYPE will be empty
  # We can swith the order of reading $DIR and $TYPE, or apply the follwoing
  if [[ -z $TYPE ]]; then
     TYPE=$DIR
     DIR=''
  fi
  if [[ -z $DIR ]]; then
     echo "Dir : $TYPE | not spec.  |           " >>  ${SYSLOG}
     exit
  fi
  if [ -e $DIR ]; then
     echo "Dir : $TYPE |   found    | '${DIR}'  " >>  ${SYSLOG}
  else
     echo "Dir : $TYPE | not found  | '${DIR}'  " >>  ${SYSLOG}
     echo ""
     logMessage "Multi-stage aborted ... " >>  ${SYSLOG}
     echo "Check directory existance failed, see the ${SYSLOG}."
     echo "Multi-stage aborted ... "
     echo ""
     exit 
  fi
}
#
# ---------------------------------------------------------------------------
checkFileExistence()
{ FPATH=$1
  FTYPE=$2
  FNAME=$3
  if [[ -z $FNAME ]]; then
     echo "File: $FTYPE | not spec.  |                    " >>  ${SYSLOG}
     exit               
  fi
  if [ $FNAME ]; then
     if [ -e "${FPATH}/${FNAME}" ]; then
        # logMessage "The $FTYPE '${FPATH}/${FNAME}' was found."
        echo "File: $FTYPE |   found    | '${FPATH}/${FNAME}'." >>  ${SYSLOG}
     else
        echo "File: $FTYPE | not found  | '${FPATH}/${FNAME}'." >>  ${SYSLOG}
        echo ""
        logMessage "Multi-stage aborted ... " >>  ${SYSLOG}
        echo "Check file existance failed, see the ${SYSLOG}."
        echo "Multi-stage aborted ... "
        echo ""
        exit
     fi
  fi
}
# ---------------------------------------------------------------------------
checkCPUExistence()
{ rqstdCPU=$1
  writer=$2
  capacityCPU=`grep -c ^processor /proc/cpuinfo`
  if [[ -z $rqstdCPU ]]; then
     fatal "The number of CPU was not specified in the configuration file."
  fi
  if [ $rqstdCPU ]; then
  ttl=`expr $rqstdCPU + $writer`
     if [ $capacityCPU -gt $ttl ]; then
        logMessage "Total requested computation cpu node(s) $ttl out of ${capacityCPU} available on ${platform}"
     else 
        fatal "$ttl computation cpu node(s) requested that is more than existing $exstngCPU computation cpu nodes available on ${platform}"
     fi
  fi
}
# ---------------------------------------------------------------------------
#                             WRITING  FORT.15 AND FORT.22 
#
writeControls()
{ cntrloptn=$1            # control option
  rndr=$2                 # run directory
  # Linking control writer Perl to run dir.
  ln -fs $SCRDIR/control_file_gen.pl  $rndr/control_file_gen.pl     
  # linking Pcalc.pm and ArraySub.pm
  ln -fs $SCRDIR/PERL/Date            $rndr/Date
  ln -fs $SCRDIR/PERL/ArraySub.pm     $rndr/ArraySub.pm
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
#                              ADCPREP: DECOMPOSING INPUTS
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
#                              PADCIRC: PARALLEL ADCIRC
runPADCIRC()
{ NP=$1
  cd $SCRDIR
  . $CONFIG
  ln -s $EXEDIR/padcirc $RUNDIR/padcirc
  cd $RUNDIR
  mpirun -n $NP ./padcirc >> $RUNDIR/padcirc.log 2>&1
  cd -
}
# ---------------------------------------------------------------------------------
#                         
#                         PADCSWAN: PARALLEL ADCIRC + SWAN
runPADCSWAN()
{ NP=$1
  cd $SCRDIR
  . $CONFIG
  ln -s $EXEDIR/padcswan $RUNDIR/padcswan
  cd $RUNDIR
  mpirun -n $NP ./padcswan >> $RUNDIR/padcswan.log 2>$1
  cd -
}
#
# ---------------------------------------------------------------------------------
#                         
#        Checking the existence of input files, executables, & directories
#
logMessage "Reading the configuration file: ${CONFIG}."
logMessage "Checking for the existence of required files and directories started ... "
# check existence of all required files and directories
echo "" >> ${SYSLOG}
echo "                  File/Directory                |   Status   |                  Path"  >> ${SYSLOG}
echo "------------------------------------------------|------------|------------------------------------"  >> ${SYSLOG}
# ADCIRC executable files
checkDirExistence  $EXEDIR   "ADCIRC executables directory             "
checkFileExistence $EXEDIR   "ADCIRC preprocessing executable          " adcprep
checkFileExistene  $EXEDIR   "ADCIRC parallel executable               " padcirc
checkFileExistence $EXEDIR   "hotstart time extraction executable      " hstime
# SWAN executable and input files
if [[ $WAVES = on ]]; then
   checkFileExistence $EXEDIR    "ADCIRC+SWAN parallel executable          " padcswan
fi
# Perl
checkDirExistence  $PERL5LIB        "Perl directory for the Date::Pcalc       "
checkDirExistence  ${PERL5LIB}/Date "Perl subdirectory for the Pcalc.pm       "
checkFileExistence ${PERL5LIB}/Date "Perl module for date calculations        " Pcalc.pm
# Stage one input files
checkDirExistence  $s1_INPDIR "S1 directory for input files             "
checkFileExistence $s1_INPDIR "S1 mesh file                             " $s1_grd
checkFileExistence $s1_INPDIR "S1 template fort.15 file                 " $s1_cntrl
# fort.13 (nodal attributes) file is optional
if [[ ! -z $s1_ndlattr && $s1_ndlattr != null ]]; then
   checkFileExistence $s1_INPDIR "S1 nodal attributes (fort.13) file       " $s1_ndlattr
fi
# Stage two input files
checkDirExistence  $s2_INPDIR "S2 directory for input files             "
checkFileExistence $s2_INPDIR "S2 mesh file                             " $s2_grd
checkFileExistence $s2_INPDIR "S2 emplate fort.15 file                  " $s2_cntrl
# fort.13 (nodal attributes) file is optional
if [[ ! -z $s2_ndlattr && $s2_ndlattr != null ]]; then
   checkFileExistence $s2_INPDIR "S2 nodal attributes (fort.13) file       " $s2_ndlattr
fi
# meteorology
checkDirExistence $met_INPDIR "directory for meteorological input file  "
if [[ $MET == gridded ]]; then
   if [ -z ${met_INPDIR}/${basinP} ] && [ -z ${met_INPDIR}/${basinUV} ]; then
      checkFileExistence $met_INPDIR "Met: basin scale pressure nws 12         " $basinP
      checkFileExistence $met_INPDIR "Met: basin scale wind nws 12             " $basinUV
   fi
   if [ -z ${met_INPDIR}/${regionalP} ] && [ -z ${met_INPDIR}/${regionalUV} ]; then 
      checkFileExistence $met_INPDIR "Met: regional scale pressure nws 12      " $regionalP
      checkFileExistence $met_INPDIR "Met: regional scale wind nws 12          " $regionalUV
   fi
fi
if [[ $MET == NHC ]]; then
   checkFileExistence $met_INPDIR  "Met: meteorological file nws 19 (20)     " $NHCmet
fi
# checkDirExistence $OUTPUTDIR "directory for post processing scripts"
#
#if [[ $MET = NHC ]]; then
#   checkFileExistence $EXEDIR "asymmetric metadata generation executable" aswip
#fi
# if [[ $MET = gridded ]]; then
#    checkFileExistence $SCRIPTDIR "NAM output reprojection executable (from lambert to geographic)" awip_lambert_interp.x
#   checkFileExistence $SCRIPTDIR "GRIB2 manipulation and extraction executable" wgrib2
# fi
#if [[ $VARFLUX = on || $VARFLUX = default ]]; then
#   checkFileExistence $INPUTDIR "River elevation initialization file " $RIVERINIT
#   checkFileExistence $INPUTDIR "River flux default file " $RIVERFLUX
#fi
#
if [[ $ELEVSTATIONS != null ]]; then
   checkFileExistence $s2_INPDIR "ADCIRC elevation stations file           " $ELEVSTATIONS
fi
if [[ $VELSTATIONS && $VELSTATIONS != null ]]; then
   checkFileExistence $s2_INPDIR "ADCIRC velocity stations file            " $VELSTATIONS
fi
if [[ $METSTATIONS && $METSTATIONS != null ]]; then
   checkFileExistence $s2_INPDIR "ADCIRC meteorological stations file      " $METSTATIONS
fi
# SWAN executable and input files
if [[ $WAVES = on ]]; then
   checkFileExistence $s2_INPDIR "SWAN init. template file for stage two   " swaninit.template
   checkFileExistence $s2_INPDIR "SWAN cntrl template file for state two   " $s2_swan26
fi
#if [[ $HOTORCOLD = hotstart ]]; then
#   if [[ $HOTSTARTFORMAT = netcdf ]]; then
#      if [[ -d $LASTSUBDIR/hindcast ]]; then
#         checkFileExistence "" "ADCIRC hotstart (fort.67.nc) file " $LASTSUBDIR/hindcast/fort.67.nc
#      fi
#      if [[ -d $LASTSUBDIR/nowcast ]]; then
#         checkFileExistence "" "ADCIRC hotstart (fort.67.nc) file " $LASTSUBDIR/nowcast/fort.67.nc
#      fi
#   else
#      if [[ -d $LASTSUBDIR/hindcast ]]; then
#         checkFileExistence "" "ADCIRC hotstart (fort.67) file " $LASTSUBDIR/hindcast/PE0000/fort.67
#      fi
#      if [[ -d $LASTSUBDIR/nowcast ]]; then
#         checkFileExistence "" "ADCIRC hotstart (fort.67) file " $LASTSUBDIR/nowcast/PE0000/fort.67
#      fi
#   fi
#fi
#
#checkFileExistence $OUTPUTDIR "postprocessing initialization script" $INITPOST
#checkFileExistence $OUTPUTDIR "postprocessing script" $POSTPROCESS
#checkFileExistence $OUTPUTDIR "email notification script" $NOTIFY_SCRIPT
#checkFileExistence $OUTPUTDIR "data archival script" $ARCHIVE
#
echo "" >> ${SYSLOG}
#
checkCPUExistence $NCPU $outputWriter
# send out an email to notify users that the ASGS is ACTIVATED
# ${OUTPUTDIR}/${NOTIFY_SCRIPT} $HOSTNAME $STORM $YEAR $RUNDIR advisory enstorm $GRIDFILE activation $EMAILNOTIFY $SYSLOG "${ACTIVATE_LIST}" $ARCHIVEBASE $ARCHIVEDIR >> ${SYSLOG} 2>&1
#
# OLDADVISDIR=null
# CSDATE=$COLDSTARTDATE
# START=$HOTORCOLD
# if [[ -d $LASTSUBDIR/hindcast ]]; then
#    OLDADVISDIR=$LASTSUBDIR/hindcast
# else
#    OLDADVISDIR=$LASTSUBDIR/hindcast
# fi
# ---------------------------------------------------------------------------------
# 
#                                S T A G E   O N E
#
# -------------------------- G R I D D E D     M E T ------------------------------ 
#
echo ""  >> ${SYSLOG} 2>&1
logMessage "Stage 1 -- gridded meteorology"
if [ "$MET" == "gridded" ]; then
   RUNDIR=${SCRDIR}${ID}/S1/TideMetSpinUp
   logMessage "Linking input files into $RUNDIR ."
   # Linking the stage one grid
   ln -s ${s1_INPDIR}/${s1_grd}         $RUNDIR/fort.14
   # Linking the stage one nodal attribute if specified
   if [[ ! -z $s1_ndlattr && $s1_ndlattr != null ]]; then
       ln -s ${s1_INPDIR}/$s1_ndlattr  $RUNDIR/fort.13
   fi
   # Link basin met if specified
   if [ ! -z "$basinP" -a "$basinP" != "null" ]; then
      ln -s ${met_INPDIR}/${basinP}        $RUNDIR/fort.221
      ln -s ${met_INPDIR}/${basinUV}       $RUNDIR/fort.222
      nwset=1
   fi
   # Link regional if specified
   if [ ! -z "$regionalP" -a "$regionalP" != "null" ]; then
      ln -s ${met_INPDIR}/${regionalP}     $RUNDIR/fort.223
      ln -s ${met_INPDIR}/${regionalUV}    $RUNDIR/fort.224
      nwset=2
   fi
   # Defining/renaming for control options
   ENSTORM="S1.gridded"
   stormDir=$RUNDIR
   CONTROLTEMPLATE=${s1_cntrl}
   GRIDNAME=${s1_grd}
   dt=${S1_dt}
   nws='12'
   . $CONFIG 
   #
   cp $BNDIR/archive.boundary.nodes/$BNNAME  $RUNDIR/boundaryNodes
   CONTROLOPTIONS=" --stormDir $stormDir --scriptdir $SCRDIR --cst $CSDATE --endtime $HINDCASTLENGTH --dt $dt --hsformat $HOTSTARTFORMAT --controltemplate $s1_INPDIR$CONTROLTEMPLATE --fort61freq "$BCFREQ" --name $ENSTORM --met $MET --nws $nws --windInterval $windInterval --nwset $nwset --boundaryNodes boundaryNodes"
   CONTROLOPTIONS="$CONTROLOPTIONS --bctype $BCTYPE --eventdate $EVENTDATE --stage2_spinUp $S2SPINUP --hotswan $hotswan"
   CONTROLOPTIONS="$CONTROLOPTIONS --gridname $GRIDNAME" # for run.properties
   # writing fort.15 and fort.22
   writeControls $CONTROLOPTIONS $RUNDIR
   startRun=`date '+%Y%m%d%H%M%S'`      
fi
#
# ---------------------------------- N H C   MET ----------------------------------
#
if [ "$MET" == "NHC" ]; then
#     
#       T I D E      O N L Y 
# 
   echo ""  >> ${SYSLOG} 2>&1
   logMessage "Stage 1 -- Tide only for NHC meteorology"
   RUNDIR=$SCRDIR/${ID}/S1/TideSpinUp/
   # saving RUNDIR if HRLA only tide spin-up required
   RUNDIR_NHC1=$RUNDIR
   #
   logMessage "Linking input files into $RUNDIR ."
   # Linking the stage one grid
   ln -s ${s1_INPDIR}/${s1_grd}         $RUNDIR/fort.14
   # Linking the stage one nodal attribute if specified
   if [[ ! -z $s1_ndlattr && $s1_ndlattr != null ]]; then
      ln -s ${s1_INPDIR}/$s1_ndlattr  $RUNDIR/fort.13
   fi        
   # Defining/renaming for control options
   ENSTORM="S1_1_NHC"
   stormDir=$RUNDIR
   CONTROLTEMPLATE=${s1_cntrl}
   GRIDNAME=${s1_grd}
   dt=${S1_dt}
   nws='0'
   . ${CONFIG}
   #
   cp $BNDIR/archive.boundary.nodes/$BNNAME  $RUNDIR/boundaryNodes
   CONTROLOPTIONS=" --stormDir $stormDir --scriptdir $SCRDIR --cst $CSDATE --endtime $HINDCASTLENGTH --dt $dt --hsformat $HOTSTARTFORMAT --controltemplate $s1_INPDIR$CONTROLTEMPLATE --fort61freq "$BCFREQ" --name $ENSTORM --met $MET --nws $nws --boundaryNodes boundaryNodes"
   CONTROLOPTIONS="$CONTROLOPTIONS --bctype $BCTYPE --eventdate $EVENTDATE --stage2_spinUp $S2SPINUP"
   CONTROLOPTIONS="$CONTROLOPTIONS --gridname $GRIDNAME" # for run.properties
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
   logMessage "Stage 1 (NHC Tide only): PADCIRC job is submitted."
   #
   cd $RUNDIR
   runPADCIRC $NCPU
   logMessage "PADCIRC job is submitted."
   cd -
   startRun=`date '+%Y%m%d%H%M%S'`
#       
#       T I D E   AND   M E T
#
   echo ""  >> ${SYSLOG} 2>&1
   logMessage "Stage 1 -- Tide & met for NHC meteorology"
   RUNDIR_OLD=${RUNDIR}
   RUNDIR=$SCRDIR/${ID}/S1/TideMetSpinUp/
   # saving RUNDIR if HRLA only tide spin-up required
   RUNDIR_NHC2=$RUNDIR
   # Linking hotstart file from tide only run
   ln -s  $RUNDIR_OLD/PE0000/fort.67 $RUNDIR/fort.67
   # Copying tide only fort.63 to append if HRLA needs to be spun up
   if [ $S2SPINUP -gt 0 ]; then
      cp  $RUNDIR_OLD/fort.63 $RUNDIR/fort.63
   fi
   logMessage "Linking input files into $RUNDIR ."
   # Linking the stage one grid
   ln -s ${s1_INPDIR}/${s1_grd}         $RUNDIR/fort.14
   # Linking the stage one nodal attribute if specified
   if [[ ! -z $s1_ndlattr && $s1_ndlattr != null ]]; then
      ln -s ${s1_INPDIR}/$s1_ndlattr    $RUNDIR/fort.13
   fi 
   # Linking meteorological file
   ln -s ${met_INPDIR}/${NHCmet}        $RUNDIR/fort.22
   # Defining/renaming for control options
   ENSTORM="S1_2_NHC"
   stormDir=$RUNDIR
   CONTROLTEMPLATE=${s1_cntrl}
   GRIDNAME=${s1_grd}
   dt=${S1_dt}
   nws='20'
   metfile=${met_INPDIR}/${NHCmet}
   hstime="on"
   cd ${SCRDIR}
   . ${CONFIG}
   #
   cp $BNDIR/archive.boundary.nodes/$BNNAME  $RUNDIR/boundaryNodes
   CONTROLOPTIONS=" --stormDir $stormDir --scriptdir $SCRDIR --cst $CSDATE --endtime $HINDCASTLENGTH --dt $dt --hsformat $HOTSTARTFORMAT --controltemplate $s1_INPDIR$CONTROLTEMPLATE --fort61freq "$BCFREQ" --name $ENSTORM --met $MET --nws $nws --metfile $metfile --boundaryNodes boundaryNodes"
   CONTROLOPTIONS="$CONTROLOPTIONS --bctype $BCTYPE --eventdate $EVENTDATE --stage2_spinUp $S2SPINUP --hstime $hstime "
   CONTROLOPTIONS="$CONTROLOPTIONS --gridname $GRIDNAME" # for run.properties
   # writing fort.15 and fort.22
   writeControls $CONTROLOPTIONS $RUNDIR
   runPADCIRC $NCPU
   logMessage "Stage 1 (NHC Tide & Met): PADCIRC job is submitted."
fi
# ----------------------------------------------------------------------------------
# 
#       Stage one gridded or stage 2 NHC
#
# Decomposing grid, control, and nodal attribute file
logMessage "Running adcprep to partition the mesh for $NCPU compute processors." 
prepFile partmesh 
logMessage "Running adcprep to partition the mesh for $NCPU compute processors." 
prepFile prepall 
logMessage "Running adcprep to prepare new fort.15 file."
prepFile prep15 
#
logMessage "PADCIRC job has finished."
#
cd $RUNDIR
runPADCIRC $NCPU
logMessage "PADCIRC job is submitted."
cd - 
# ------------------
# Subrouting to generate boundary condition (fort.19)
prepBC()
{ Tstep=$1	# BCprvdr = Boundary condition extract
  Elev=$2
  dir=$3
  cd $dir   
  ln -fs $BNDIR/archive.boundary.nodes/$BNNAME  Boundary_Node
  ln -fs $BNDIR/bcGen.61.x  bcGen.61.x
  ./bcGen.61.x $Tstep $Elev
  cd -
}
# -----------------------------------------------------------------------------------
#
# Creating boundary forcing file
#
# The following conditions are required for NHC type only
if [[ $MET == NHC || $S2SPINUP -gt 0 ]]; then
   logMessage "Boundary condition to force HRLA tide only is being created"
   mv $RUNDIR_NHC1/fort.14 $RUNDIR_NHC1/fort.14_parent
   ln -s ${s2_INPDIR}/${s2_grd}         $RUNDIR_NHC1/fort.14
   prepBC $BCFREQ fort.61 $RUNDIR_NHC1
   mv $RUNDIR_NHC1/fort.19 $RUNDIR_NHC1/fort.19_1  # tide only
   mv $RUNDIR_NHC1/fort.14 $RUNDIR_NHC1/fort.14_child
fi
# 
# For gridded and NHC tide and met.  
logMessage "Boundary condition to force HRLA tide and met is being created"
mv $RUNDIR/fort.14 $RUNDIR/fort.14_parent
ln -s ${s2_INPDIR}/${s2_grd}         $RUNDIR/fort.14
prepBC $BCFREQ fort.61 $RUNDIR
mv $RUNDIR/fort.19 $RUNDIR/fort.19_2              # tide and met 
mv $RUNDIR/fort.14 $RUNDIR/fort.14_child
#
# ---------------------------------------------------------------------------------
# 
#                                S T A G E   T W O
#
# ----------------------------- G R I D E D    M E T ------------------------------ 
#
RUNDIR_OLD=$RUNDIR
#
# Redirecting to HRLA directory: S2
# turning off the nodal attribute
nddlAttribute="off"
#
if [ "$MET" == "gridded" ]; then
   echo ""  >> ${SYSLOG} 2>&1
   logMessage "Stage 2 -- gridded meteorology"
   RUNDIR=$SCRDIR/${ID}/S2/TideMetSpinUp 
   # Linking fort.19 to run directory for HRLA
   if [ ! -z $RUNDIR_OLD/fort.19 ]; then
      ln -s $RUNDIR_OLD/fort.19_2    $RUNDIR/fort.19
   else
      fatal "Non-periodic elevation boundary condition input file does not exist."
   fi
   #
   cd $SCRDIR
   . $CONFIG
   # Linking the stage two grid
   ln -s ${s2_INPDIR}/${s2_grd}         $RUNDIR/fort.14
   # Linking the stage one nodal attribute if specified
   if [[ ! -z $s2_ndlattr && $s2_ndlattr != null ]]; then
      ln -s ${s2_INPDIR}/$s2_ndlattr    $RUNDIR/fort.13       
      nddlAttribute="on"      # For bottom friction in swan
   fi
   # Link basin met if specified
   if [ ! -z "$basinP" -a "$basinP" != "null" ]; then
      ln -s ${met_INPDIR}/${basinP}        $RUNDIR/fort.221
      ln -s ${met_INPDIR}/${basinUV}       $RUNDIR/fort.222
      nwset=1
   fi
   # Link regional if specified
   if [ ! -z "$regionalP" -a "$regionalP" != "null" ]; then
      ln -s ${met_INPDIR}/${regionalP}     $RUNDIR/fort.223
      ln -s ${met_INPDIR}/${regionalUV}    $RUNDIR/fort.224
      nwset=2
   fi
   # Defining/renaming for control options
   ENSTORM="S2.gridded"
   stormDir=$RUNDIR
   CONTROLTEMPLATE=${s2_cntrl}
   GRIDNAME=${s2_grd}
   dt=${S2_dt}
   nws='12'
   if [[ $WAVES = on ]]; then
      nws=`expr $nws + 300`
      cp ${s2_INPDIR}/swaninit.template         $RUNDIR/swaninit
   fi 
   cd ${SCRDIR}
   . ${CONFIG}
   CONTROLOPTIONS=" --stormDir $stormDir --scriptdir $SCRDIR --cst $CSDATE --endtime $HINDCASTLENGTH --dt $dt --hsformat $HOTSTARTFORMAT --controltemplate $s2_INPDIR$CONTROLTEMPLATE $OUTPUTOPTIONS --name $ENSTORM --met $MET --nws $nws --windInterval $windInterval --platform $platform --nwset $nwset"
   CONTROLOPTIONS="$CONTROLOPTIONS --bctype $BCTYPE --eventdate $EVENTDATE --stage2_spinUp $S2SPINUP"
   CONTROLOPTIONS="$CONTROLOPTIONS --gridname $GRIDNAME" # for run.properties
   if [[ $WAVES = on ]]; then
      CONTROLOPTIONS="${CONTROLOPTIONS} --swandt $SWANDT --swantemplate ${s2_INPDIR}/${s2_swan26} --hotswan $hotswan --ID $ID --estuary "$estuary" --nddlAttribute $nddlAttribute --swanBottomFri $fricType"
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
   if [ $WAVES == on ]; then
      runPADCSWAN $NCPU
      logMessage "PADCSWAN job is submitted."
   else
      runPADCIRC $NCPU
      logMessage "PADCIRC job is submitted."
   fi
   #
fi
#
# ----------------------------- N H C     M E T ------------------------------ 
#
RUNDIR_OLD=$RUNDIR
#
# turning off the nodal attribute
# Redirecting to HRLA directory: S2
if [ "$MET" == "NHC" ]; then
   if [ $S2SPINUP -gt 0 ]; then
      echo ""  >> ${SYSLOG} 2>&1
      logMessage "Stage 2 -- Tide only for NHC meteorology"
      RUNDIR=$SCRDIR/${ID}/S2/TideSpinUp
      if [ ! -z $RUNDIR_NHC1/fort.19 ]; then
         ln -s $RUNDIR_NHC1/fort.19_1    $RUNDIR/fort.19
      else
         fatal "Non-periodic elevation boundary condition input file does not exist."
      fi     
      #
      cd $SCRDIR
      . $CONFIG
      # Linking the stage two grid
      ln -s ${s2_INPDIR}/${s2_grd}         $RUNDIR/fort.14
      # Linking the stage two nodal attribute if specified
      if [[ ! -z $s2_ndlattr && $s2_ndlattr != null ]]; then
         ln -s ${s2_INPDIR}/$s2_ndlattr  $RUNDIR/fort.13
      fi
      #
      ENSTORM="S2_1_NHC"
      stormDir=$RUNDIR
      CONTROLTEMPLATE=${s2_cntrl}
      GRIDNAME=${s2_grd}
      dt=${S2_dt}
      nws='0'
      cd $SCRDIR
      . $CONFIG
      #
      CONTROLOPTIONS=" --stormDir $stormDir --scriptdir $SCRDIR --cst $CSDATE --endtime $HINDCASTLENGTH --dt $dt --hsformat $HOTSTARTFORMAT --controltemplate $s2_INPDIR$CONTROLTEMPLATE --name $ENSTORM --met $MET --nws $nws $OUTPUTOPTIONS"
      CONTROLOPTIONS="$CONTROLOPTIONS --bctype $BCTYPE --eventdate $EVENTDATE --stage2_spinUp $S2SPINUP"
      CONTROLOPTIONS="$CONTROLOPTIONS --gridname $GRIDNAME" # for run.properties
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
      logMessage "Stage 2 (NHC Tide only): PADCIRC job is submitted."
      #
      cd $RUNDIR
      runPADCIRC $NCPU
      logMessage "PADCIRC job is submitted."
      cd -
   fi
#
# -----------------------  T I D E   AND   M E T ----------------------------   
#
# turning off the nodal attribute
nddlAttribute="off"
      echo ""  >> ${SYSLOG} 2>&1
      logMessage "Stage 2 -- Tide & met for NHC meteorology"
      RUNDIR_OLD=$RUNDIR
      RUNDIR=$SCRDIR/${ID}/S2/TideMetSpinUp/
      ln -s $SCRDIR/${ID}/S1/TideMetSpinUp/fort.19_2    $RUNDIR/fort.19
      if [ "$S2SPINUP" -gt 0 ]; then
         # Linking hotstart file from BC tide only run 
         ln -s  $RUNDIR_OLD/PE0000/fort.67 $RUNDIR/fort.67
      fi
      logMessage "Linking input files into $RUNDIR ."
      # Linking the stage two grid
      ln -s ${s2_INPDIR}/${s2_grd}         $RUNDIR/fort.14
      # Linking the stage two nodal attribute if specified
      if [[ ! -z $s2_ndlattr && $s1_ndlattr != null ]]; then
         ln -s ${s2_INPDIR}/$s2_ndlattr    $RUNDIR/fort.13
         nddlAttribute="on"	# For bottom friction in swan
      fi
      ln -s ${met_INPDIR}/${NHCmet}        $RUNDIR/fort.22
      ENSTORM="S2_2_NHC"
      stormDir=$RUNDIR
      CONTROLTEMPLATE=${s2_cntrl}
      GRIDNAME=${s2_grd}
      dt=${S2_dt}
      nws='20'
      metfile=${met_INPDIR}/${NHCmet}
      #
      if [ "$S2SPINUP" -le 0 ]; then
         hstime="off"
      else
         hstime="on"
      fi
      #
      if [[ $WAVES = on ]]; then
         nws=`expr $nws + 300`
         cp ${s2_INPDIR}/swaninit.template        $RUNDIR/swaninit
      fi
      cd $SCRDIR
      . ${CONFIG}
      #
      CONTROLOPTIONS=" --stormDir $stormDir --scriptdir $SCRDIR --cst $CSDATE --endtime $HINDCASTLENGTH --dt $dt --hsformat $HOTSTARTFORMAT --controltemplate $s2_INPDIR$CONTROLTEMPLATE $OUTPUTOPTIONS --name $ENSTORM --met $MET --nws $nws --metfile $metfile --platform $platform"
      CONTROLOPTIONS="$CONTROLOPTIONS --bctype $BCTYPE --eventdate $EVENTDATE --stage2_spinUp $S2SPINUP --hstime $hstime "
      CONTROLOPTIONS="$CONTROLOPTIONS --gridname $GRIDNAME" # for run.properties
      if [[ $WAVES = on ]]; then
         CONTROLOPTIONS="${CONTROLOPTIONS} --swandt $SWANDT --swantemplate ${s2_INPDIR}/${s2_swan26} --hotswan $hotswan --ID $ID --estuary "$estuary" --nddlAttribute $nddlAttribute --swanBottomFri $fricType"
      fi
      #
      # writing fort.15 and fort.22
      writeControls $CONTROLOPTIONS $RUNDIR
      # 
      # if the HRLA spinup is negative, we need to create a fort.22 starting at 
      # the beginning of the stage 2 simulation that is $S2SPINUP days after
      # the start date of the fort.22
      if [ "$S2SPINUP" -lt 0 ]; then
	 shorter22start=`cat ${SYSLOG} | grep "Stage two start date is" | cut -d\' -f2 | grep -m1 ""`
         cat $RUNDIR/fort.22 | grep --after-context=2000 "$shorter22start" >> $RUNDIR/fort.22.shorter
         mv $RUNDIR/fort.22 $RUNDIR/fort.22.old
         ln -fs $RUNDIR/fort.22.shorter $RUNDIR/fort.22
      fi
      # Decomposing grid, control, and nodal attribute file
      logMessage "Redirecting to HRLA directory (S2:NHC & Met)"
      logMessage "Running adcprep to partition the mesh for $NCPU compute processors."
      prepFile partmesh
      logMessage "Running adcprep to partition the mesh for $NCPU compute processors."
      #
      prepFile prepall
      logMessage "Running adcprep to prepare new fort.15 file."
      prepFile prep15
      #
      if [ $WAVES == on ]; then
         runPADCSWAN $NCPU
         logMessage "Stage 2 (NHC Tide & Met): PADCSWAN job is submitted."
      else
         runPADCIRC $NCPU
         logMessage "Stage 2 (NHC Tide & Met): PADCIRC job is submitted."
      fi
fi
#
endRun=`date '+%Y%m%d%H%M%S'`      
# --------------------------------------------------------------------------
#
#                          P O S T    P R O C E S S I N G
#
ln -fs $SCRDIR/PERL/Date            $SCRDIR/Date
ln -fs $SCRDIR/PERL/ArraySub.pm     $SCRDIR/ArraySub.pm
#
perl ${SCRDIR}/wallClock.pl --st $startRun --et $endRun --not ${SCRDIR}/postProc/${notidy_script} --dir $RUNDIR >> ${SYSLOG} 2>&1
#
# Sending simple notification
chmod +x ${RUNDIR}/notifying.sh
PHASE="simpleNot"
${RUNDIR}/notifying.sh $ID $notify_list $PHASE $EMAILNOTIFY $RUNDIR $WAVES $platform ${SCRDIR} $TYPE ${SYSLOG} "${estuary}"
#
if [[ $TYPE = email ]]; then
	logMessage "Notification sent to $notify_list"
elif [[ $TYPE = screen ]]; then
        logMessage "Notification printed on screen"
fi
