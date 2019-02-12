#!/bin/bash
#
# Checking the existance of input files, directories, CPUs
#
SYSLOG=$1
CONFIG=$2
. ${CONFIG}
. ${mainDIR}/src/logging.sh
#
# -------------------------------------------------------
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
checkFileExistence $EXEDIR   "asymmetric metadata generation executable" aswip 
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
if [[ $MET == NHC ]]; then
   checkFileExistence $met_INPDIR  "Met: meteorological file nws 19 (20)     " $NHCmet
fi
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
#
echo "" >> ${SYSLOG}
#
checkCPUExistence $NCPU $outputWriter
#
