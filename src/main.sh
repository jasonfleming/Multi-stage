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
  echo " ################################## Help ################################### "
  echo "|                                                                           |"
  echo "| Run the main.sh in the parent directory/                                  |" 
  echo "|                                                                           |"
  echo "| Syntax:                                                                   |"
  echo "|   ./main.sh   [-c config.sh] [-m 'list of members delimited by space']    |"
  echo "|                                                                           |"
  echo "| Availbale scenarios:                                                      |"
  echo "|   NAM                               =>  insert nam                        |"
  echo "|   GEFS mean                         =>  insert GEFSmean                   |"
  echo "|   GEFS mean + 1 standard deviation  =>  insert GEFSmeanPstd               |"
  echo "|   GEFS mean - 1 standard deviaiton  =>  insert GEFSmeanMstd               |"
  echo "|   SREF mean                         =>  insert SREFmean                   |"
  echo "|   SREF mean + 1 standard deviation  =>  insert SREFmeanPstd               |"
  echo "|   SREF mean - 1 standard deviaiton  =>  insert SREFmeanMstd               |"
  echo "|                                                                           |"
  echo "| Example:                                                                  |"            
  echo "|   ./main.sh  -c full/path/config.sh  -m 'nam GEFSmean GEFSPstd'           |"
  echo "|                                                                           |" 
  echo "| Note:                                                                     |"
  echo "|      config has to be given in full path.                                 |"
  echo "|                                                                           |"
  echo "| Options:                                                                  |"
  echo "|   -c : set location of configuration file                                 |"
  echo "|   -m : list of ensemble members                                           |"
  echo "|   -h : show help                                                          |" 
  echo "|                                                                           |"
  echo " ########################################################################### "
  exit;
}
#                   
while getopts "c:m:h" optname; do    #<- first getopts for SCRIPTDIR
  case $optname in
    c) CONFIG=${OPTARG}
       if [[ ! -e $CONFIG ]]; then
          echo "ERROR: $CONFIG does not exist."
          exit $EXIT_NOT_OK
       fi
      ;;
    m) members_name=${OPTARG}
      ;;
    h) echoHelp     
      ;;
  esac
done

# Converting input members into array
members=($members_name)
lenM=${#members[@]}

#
# Read config file to find the path to $SCRIPTDIR
. ${CONFIG}
# name Multistage log file 
STARTDATETIME=`date +'%Y-%h-%d-T%H:%M'`
SYSLOG=`pwd`/multiStage-${STARTDATETIME}.log
#
# Bring in logging functions
. ${mainDIR}/src/logging.sh
#
# --------------------------------------------------------
CRRNTDIR=$(pwd)
. ${CONFIG}
#
logMessage "Creating ID directory under ${mainDIR}" 
mkdir $ID
. $CONFIG
#
# Check the existance of files, directories, CPUs --------
${mainDIR}/src/checkExist.sh ${SYSLOG} ${CONFIG}
#
# ----------------  B A C K  G R O U N D -----------------
#
##
#### S1: HINDCAST
##
#
echo ""  >> ${SYSLOG} 2>&1
${mainDIR}/src/H_s1.sh ${SYSLOG} ${CONFIG}
startRun=`date '+%Y%m%d%H%M%S'`
cycle=1
#
## 
### Starting the nowcast/forecast loop
##
##
while [ $cycle -gt 0 ]
do
#
##
#### S1: NOWCAST
##
#
echo ""  >> ${SYSLOG} 2>&1
if [ "$MET" == "background" ]; then
   ${mainDIR}/src/N_s1_gridded.sh ${SYSLOG} ${CONFIG} $cycle   &  PIDIOS=$!
   cd ${mainDIR}/GEFS/
     src/download_gefs_data.sh                                 &  PIDMIX=$!
   cd -
   wait $PIDIOS
   wait $PIDMIX
elif [ "$MET" == "TC" ]; then
   ${mainDIR}/src/N_s1_tc.sh ${SYSLOG} ${CONFIG} $cycle   
fi
#
if [ $cycle -gt 1 ]; then
   startRun=`date '+%Y%m%d%H%M%S'`
fi
#
##
#### S1: FORECAST
##
#
echo ""  >> ${SYSLOG} 2>&1
if [ "$MET" == "background" ]; then
   cd ${mainDIR}/SREF
      src/download_sref_data.sh ${CONFIG}  >> SREF.log   # Downloading SREF
   cd -
   for (( i=0; i<${lenM}; i++ )) ;
   do
     ${mainDIR}/src/F_s1_gridded.sh ${SYSLOG} ${CONFIG} $startRun ${members[$i]}
   done
elif [ "$MET" == "TC" ]; then
   ${mainDIR}/src/F_s1_tc.sh ${SYSLOG} ${CONFIG} $cycle   
fi
#
##
### BC generating
##
#
echo ""  >> ${SYSLOG} 2>&1
for (( i=0; i<${lenM}; i++ )) ;
do
   ${mainDIR}/src/bcGen.sh ${SYSLOG} ${CONFIG} ${cycle} ${members[$i]}
done
#
##
### S2: nowcast
##
#
echo ""  >> ${SYSLOG} 2>&1
if [ "$MET" == "background" ]; then
   ${mainDIR}/src/N_s2_gridded.sh ${SYSLOG} ${CONFIG} $cycle
elif [ "$MET" == "TC" ]; then
   ${mainDIR}/src/N_s2_tc.sh      ${SYSLOG} ${CONFIG} $cycle
fi 
# 
##
### S2: forecast 
##
#
echo ""  >> ${SYSLOG} 2>&1
if [ "$MET" == "background" ]; then
   for (( i=0; i<${lenM}; i++ )) ;
   do
     ${mainDIR}/src/F_s2_gridded.sh ${SYSLOG} ${CONFIG} $startRun ${members[$i]}   
   done 
elif [ "$MET" == "TC" ]; then
   ${mainDIR}/src/F_s2_tc.sh ${SYSLOG} ${CONFIG} $cycle
fi
#
##
### Next cycle
##
#
cycle=`expr $cycle + 1`
if [[ $MODE = HINDCAST ]]; then
   break         # get out of the forecast loop
fi
#
done
#
