#!/bin/bash
# --------------------------------------------------------------------------
#
# This script is the core program of the Multi-stage tool.
# It carrious out the each step of modeling process by reading the config 
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
while getopts "c:" optname; do    #<- first getopts for SCRIPTDIR
  case $optname in
    c) CONFIG=${OPTARG}
       if [[ ! -e $CONFIG ]]; then
          echo "ERROR: $CONFIG does not exist."
          exit $EXIT_NOT_OK
       fi 
       ;;
  esac
done
#
# Read config file to find the path to $SCRIPTDIR
. ${CONFIG}
# name amst log file 
STARTDATETIME=`date +'%Y-%h-%d-T%H:%M:%S'`
SYSLOG=`pwd`/amga-${STARTDATETIME}.$$.log
#
# logMessage subroutine
logMessage()
{ DATETIME=`date +'%Y-%h-%d-T%H:%M:%S'`
  MSG="[${DATETIME}] INFO: $@"
  echo ${MSG} >> ${SYSLOG}
}
#
CRRNTDIR=$(pwd)
. ${CONFIG}
echo $MET
if [ "$MET" == "grided" ]; then
	mkdir $ID
        cd $ID
	mkdir S1
          cd S1
            mkdir TideMetSpinUp
            mkdir Event
          cd -
	mkdir S2
        cd - 
        . ${CONFIG}
# stage 1
	ln -s ${s1_INPDIR}/${s1_grd}         $SCRDIR/${ID}/S1/TideMetSpinUp/fort.14
	ln -s ${s1_INPDIR}/${s1_cntrl}       $SCRDIR/${ID}/S1/TideMetSpinUp/fort.15
	ln -s ${s1_INPDIR}/${s1_ndlattr}     $SCRDIR/${ID}/S1/TideMetSpinUp/fort.13
	ln -s ${s2_INPDIR}/${s2_fort22}      $SCRDIR/${ID}/S1/TideMetSpinUp/fort.22
        ln -s ${met_INPDIR}/${basinP}        $SCRDIR/${ID}/S1/TideMetSpinUp/fort.221
        ln -s ${met_INPDIR}/${basinUV}       $SCRDIR/${ID}/S1/TideMetSpinUp/fort.222
        ln -s ${met_INPDIR}/${regionalP}     $SCRDIR/${ID}/S1/TideMetSpinUp/fort.223
        ln -s ${met_INPDIR}/${regionalUV}    $SCRDIR/${ID}/S1/TideMetSpinUp/fort.224
#	
	 # after finishing sate 1, it changes to stage 2 direcotry
        RUNDIR=$SCRDIR/${ID}/S1/TideMetSpinUp/ 
# stage 2
	ln -s ${s2_INPDIR}/${s2_grd}         $SCRDIR/${ID}/S2/fort.14
        ln -s ${s2_INPDIR}/${s2_cntrl}       $SCRDIR/${ID}/S2/fort.15
        ln -s ${s2_INPDIR}/${s2_ndlattr}     $SCRDIR/${ID}/S2/fort.13
        ln -s ${s2_INPDIR}/${s2_swan26}      $SCRDIR/${ID}/S2/fort.26
	ln -s ${s2_INPDIR}/swaninit          $SCRDIR/${ID}/S2/swaninit
	ln -s ${s2_INPDIR}/${s2_fort22}      $SCRDIR/${ID}/S2/fort.22
        ln -s ${met_INPDIR}/${basinP}        $SCRDIR/${ID}/S2/fort.221
	ln -s ${met_INPDIR}/${basinUV}       $SCRDIR/${ID}/S2/fort.222
	ln -s ${met_INPDIR}/${regionalP}     $SCRDIR/${ID}/S2/fort.223
	ln -s ${met_INPDIR}/${regionalUV}    $SCRDIR/${ID}/S2/fort.224
fi
#
# Subroutine to run adcprep.
prepFile()
{ JOBTYPE=$1
   . ${CONFIG}
   ln -fs $EXEDIR/adcprep $RUNDIR/adcprep
   cd $RUNDIR
   ./adcprep --np $NCPU --${JOBTYPE} >> $RUNDIR/adcprep.log 2>&1
   cd -
}
#
# Decomposing grid, control, and nodal attribute file
logMessage "Running adcprep to partition the mesh for $NCPU compute processors." 
prepFile partmesh 
logMessage "Running adcprep to partition the mesh for $NCPU compute processors." 
prepFile prepall 
logMessage "Running adcprep to prepare new fort.15 file."
prepFile prep15 
#
# Subroutine to run PADCIRC
runPADCIRC()
{ NP=$1
  cd $SCRDIR
  . ${CONFIG}
  ln -s $EXEDIR/padcirc $RUNDIR/padcirc
  cd $RUNDIR
  mpirun -n $NP ./padcirc >> $RUNDIR/padcirc.log 2>&1
  cd -
}
runPADCSWAN()
{ NP=$1
  cd $SCRDIR
  . ${CONFIG}
  ln -s $EXEDIR/padcswan $RUNDIR/padcswan
  cd $RUNDIR
  mpirun -n $NP ./padcswan >> $RUNDIR/padcswan.log 2>$1
  cd -
}
# 
# Submitting padcirc job
if [ "$MET" == "grided" ]; then
	cd $RUNDIR
	runPADCIRC $NCPU
	logMessage "PADCIRC job is submitted."
        cd - 
fi
#
logMessage "PADCIRC job has finished."
#
# Subrouting to generate boundary condition (fort.19)
prepBC()
{ Tstep=$1	# BCprvdr = Boundary condition extract
  Elev=$2
  cd $RUNDIR
  ln -fs $BNDIR/archive.boundary.nodes/$BNNAME  Boundary_Node
  ln -fs $BNDIR/pull_fort19.x  pull_fort19.x
  ./pull_fort19.x $Tstep $Elev
  cd -
}
# Creating boundary forcing file
logMessage "Boundary condition to force HRLA is being created"
prepBC $BCFREQ fort.63
#
# -------------------------------------------------------
#							 |
#                    Stage 2 - HRLA                      |
#						         |
# -------------------------------------------------------
# Redirecting to HRLA directory: S2
RUNDIR_S1=$RUNDIR
RUNDIR=$SCRDIR/${ID}/S2/
# Linking fort.19 to run directory for HRLA
ln -fs $RUNDIR_S1/fort.19 $RUNDIR/fort.19
# Decomposing grid, control, and nodal attribute file
logMessage "Redirecting to HRLA directory (S2)"
logMessage "Running adcprep to partition the mesh for $NCPU compute processors."
prepFile partmesh
logMessage "Running adcprep to partition the mesh for $NCPU compute processors."
prepFile prepall
logMessage "Running adcprep to prepare new fort.15 file."
prepFile prep15
#
# Submitting padcirc job
if [ "$MET" == "grided" ]; then
        cd $RUNDIR
        runPADCSWAN $NCPU
        logMessage "PADCSWAN job is submitted."
        cd -
fi
#
