#!/bin/bash
#
# Creating oundary condition
#
#
############################################################################################
#
# Architecture
#
#     (1) Create fort.19 of current nowcast of state one
#         (2) Append this fort.19 to fort.19 of previous cycle that has been appended
#             to fort.19 of previous run all the way down to 1st cycle
#             NOTE: You should keep the last run for this purpose
#	            For storage reason, you can delete previous runs
#                   before the last run.
#             (3) create fort.19 of the forecast of stage one
#                 This has to contain info from previous run.
#                 So, this fort.19 is appended to fort.19 created from nowcast
#                 that has been appended to previous nowcast runs.
#
############################################################################################

# Reading in arguments
SYSLOG=$1
CONFIG=$2
cycle=$3
member=$4

#
. $CONFIG
. ${mainDIR}/src/logging.sh
workingDIR=$mainDIR$ID
cycleDIR=`cat $mainDIR$ID/currentCycle`
nowcastDIR=$mainDIR$ID/$cycleDIR/nowcast/S1
forecastDIR=$mainDIR$ID/$cycleDIR/$member/S1

# Subrouting to generate boundary condition (fort.19)
prepBC()
{ Tstep=$1	# BCprvdr = Boundary condition extract
  Elev=$2
  dir=$3
  cd $dir   
  ln -fs $BNDIR/bcGen.61.x  
  ./bcGen.61.x $Tstep $Elev
  cd -
}
# --------------------------------------------------------------------------

# Creating boundary forcing file
# From the nowcast
logMessage "Boundary condition to force HRLA from nowcast is being created"

mv $nowcastDIR/fort.14 $nowcastDIR/fort.14_parent
ln -s ${s2_INPDIR}/${s2_grd}         $nowcastDIR/fort.14
prepBC $BCFREQ fort.61 $nowcastDIR
mv $nowcastDIR/fort.14 $nowcastDIR/fort.14_child

## Merging current fort.19 to previous cycles
if [ $cycle -gt 1 ]; then        # has to be cat to fort.19 of the nowcast of the previous cycle
   lastDIR=`cat $workingDIR/currentCycle.old`
   cp $workingDIR/$lastDIR/nowcast/S1/fort.19_1  $nowcastDIR/fort.19_previous_now
   sed -i '1d' $nowcastDIR/fort.19 #current
   cat $nowcastDIR/fort.19_previous_now $nowcastDIR/fort.19 > $nowcastDIR/fort.19_1
else 
   mv $nowcastDIR/fort.19 $nowcastDIR/fort.19_1              # tide and met 
fi

# From the forecast
logMessage "Boundary condition to force HRLA from forecast is being created"
mv $forecastDIR/fort.14 $forecastDIR/fort.14_parent
ln -s ${s2_INPDIR}/${s2_grd}        $forecastDIR/fort.14
prepBC $BCFREQ fort.61 $forecastDIR
mv $forecastDIR/fort.14 $forecastDIR/fort.14_child

# cat fort.19_1 and fort.19_2 together, forecast run hotstarts from nowcast 
# and requires the fort.19 to contain bc from nowcast. The first lines of the
# the merged fort.19 run will be skipped in forecast run of stage two.
cp $nowcastDIR/fort.19_1 $forecastDIR/fort.19_1
sed -i '1d' $forecastDIR/fort.19   # deleting the header of fort.19 created by forecast
cat $forecastDIR/fort.19_1 $forecastDIR/fort.19 > $forecastDIR/fort.19_2 #cat fort.19 of nowcast (fort.19_1) & fort.19 of forecast created in stage one 
if [ -e $nowcastDIR/fort.19_1 ] && [ -e $forecastDIR/fort.19_2 ]; then
   logMessage "fort.19_1 from nowcast & fort.19_2 from merged nowcast and forecast runs successfully created"
else
   fatal "Either fort.19_1 from nowcast or fort.19_2 from merged nowcast and forecast runs not successfully created"
fi

# Renaming back
rm $nowcastDIR/fort.14_child
mv $nowcastDIR/fort.14_parent $nowcastDIR/fort.14
