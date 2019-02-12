#!/bin/bash
#
# Stage 1
# Background met.
# hindcast
#
SYSLOG=$1
CONFIG=$2
# ---------------------------------------------------------------------------
#                logMessage subroutine (containing date) 
#
logMessage() 
{ DATETIME=`date +'%Y-%h-%d-T%H:%M:%S'`
  MSG="[${DATETIME}] INFO: $@"
  echo ${MSG} >> ${SYSLOG}
}
# ---------------------------------------------------------------------------
#                   log an error message, execution halts 
#
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
#
. $CONFIG
mkdir ${mainDIR}${ID}/hindcast
RUNDIR=${mainDIR}${ID}/hindcast
ENSTORM="hindcast"
# --------------------------------------------------------------------------------
#                          State file for tropical cyclone
if [[ $MET = TC ]]; then
   echo $ENSTORM > ${mainDIR}${ID}/currentCycle
fi
# -------------------------------------------------------------------------------
#
#                                 Main Body
#
echo ""  >> ${SYSLOG} 2>&1
echo ""  >> ${SYSLOG} 2>&1
logMessage "Stage 1 -- Background meteorology, hindcast in $RUNDIR"
# Linking the stage one grid
ln -s ${s1_INPDIR}/${s1_grd}         $RUNDIR/fort.14
# Linking the stage one nodal attribute if specified
if [[ ! -z $s1_ndlattr && $s1_ndlattr != null ]]; then
   ln -s ${s1_INPDIR}/$s1_ndlattr  $RUNDIR/fort.13
fi
#
# Defining/renaming for control options
stormDir=$RUNDIR
CONTROLTEMPLATE=${s1_cntrl}
GRIDNAME=${s1_grd}
dt=${S1_dt}
nws='0'
. $CONFIG
#
CONTROLOPTIONS=" --stormDir $stormDir --scriptdir $mainDIR --cst $CSDATE --endtime $HINDCASTLENGTH --dt $dt --hsformat $HOTSTARTFORMAT --controltemplate $s1_INPDIR$CONTROLTEMPLATE --fort61freq "$BCFREQ" --name $ENSTORM --met $MET --nws $nws --nwset $nwset"
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
cd $RUNDIR
runPADCIRC $NCPU
logMessage "PADCIRC job is submitted."
cd -
echo ""  >> ${SYSLOG} 2>&1
#
# added for TC
cat $ENSTORM > $workingDIR/currentCyle
