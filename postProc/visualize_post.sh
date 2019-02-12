#!/bin/bash
#
CONFIG=$1
RUNDIR=$2
cycleDIR=$3
HOSTNAME=$4
ENSTORM=$5
#CSDATE=$6      # Rename to STARTDATE to avoid conflict between STARTDATE of config and the 6th arguement
STARTDATE=$6
GRIDFILE=$7   
SYSLOG=$8  
stage=$9   
#
. $CONFIG
. ${mainDIR}/src/logging.sh
#
OUTPUTDIR=$mainDIR/postProc
cd $RUNDIR
# -------------------------------------------------------------------------
#             G N U P L O T   F O R   L I N E   G R A P H S
# -------------------------------------------------------------------------

# transpose elevation output file so that we can graph it with gnuplot
STATIONELEVATION=${RUNDIR}/fort.61
if [[ -e $STATIONELEVATION || -e ${STATIONELEVATION}.nc ]]; then
   if [[ -e $STATIONELEVATION.nc ]]; then
      ${OUTPUTDIR}/netcdf2adcirc.x --datafile ${STATIONELEVATION}.nc 2>> ${SYSLOG}
   fi
   perl ${OUTPUTDIR}/station_transpose.pl --filetotranspose elevation --controlfile ${RUNDIR}/fort.15 --stationfile ${STATIONELEVATION} --format space --coldstartdate $STARTDATE --gmtoffset 0 --timezone UTC --units si 2>> ${SYSLOG}
fi

# transpose wind velocity output file so that we can graph it with gnuplot
STATIONVELOCITY=${RUNDIR}/fort.72
if [[ -e $STATIONVELOCITY || -e ${STATIONVELOCITY}.nc ]]; then
   if [[ -e $STATIONVELOCITY.nc ]]; then
      ${OUTPUTDIR}/netcdf2adcirc.x --datafile ${STATIONVELOCITY}.nc 2>> ${SYSLOG}
   fi
   perl ${OUTPUTDIR}/station_transpose.pl --filetotranspose windvelocity --controlfile ${RUNDIR}/fort.15 --stationfile ${STATIONVELOCITY} --format space --vectorOutput raw --coldstartdate $STARTDATE --gmtoffset 0 --timezone UTC --units si 2>> ${SYSLOG}
   
   # Creating direction file
   ${OUTPUTDIR}/uvTOgeo_station.x fort.72_transpose.txt
fi

# transpose current velocity output file so that we can graph it with gnuplot
STATIONVELOCITY=${RUNDIR}/fort.62
if [[ -e $STATIONVELOCITY || -e ${STATIONVELOCITY}.nc ]]; then
   if [[ -e $STATIONVELOCITY.nc ]]; then
      ${OUTPUTDIR}/netcdf2adcirc.x --datafile ${STATIONVELOCITY}.nc 2>> ${SYSLOG}
   fi
   perl ${OUTPUTDIR}/station_transpose.pl --filetotranspose velocity --controlfile ${RUNDIR}/fort.15 --stationfile ${STATIONVELOCITY} --format space --vectorOutput raw --coldstartdate $STARTDATE --gmtoffset 0 --timezone UTC --units si 2>> ${SYSLOG}
fi

# transpose wave velocity output file so that we can graph it with gnuplot
STATIONELEVATION=${RUNDIR}/swan.61
if [[ -e $STATIONELEVATION || -e ${STATIONELEVATION}.nc ]]; then
   if [[ -e $STATIONELEVATION.nc ]]; then
      ${OUTPUTDIR}/netcdf2adcirc.x --datafile ${STATIONELEVATION}.nc 2>> ${SYSLOG}
   fi
   perl ${OUTPUTDIR}/station_transpose.pl --filetotranspose elevation --controlfile ${RUNDIR}/fort.15 --stationfile ${STATIONELEVATION} --format space --coldstartdate $STARTDATE --gmtoffset 0 --timezone UTC --units si 2>> ${SYSLOG}
fi

# switch to plots directory
if [[ -e ${RUNDIR}/fort.61_transpose.txt || -e ${RUNDIR}/fort.72_transpose.txt ]]; then
   initialDirectory=`pwd`;
   mkdir ${RUNDIR}/plots 2>> ${SYSLOG}
   mv *.txt *.csv ${RUNDIR}/plots 2>> ${SYSLOG}
   cd ${RUNDIR}/plots
   # generate gnuplot scripts for elevation data
   ln -fs $PERL5LIB/Date ${RUNDIR}/plots/Date
   if [[ -e ${RUNDIR}/plots/fort.61_transpose.txt ]]; then
      logMessage "Generating gnuplot script for $ENSTORM hydrographs."
      perl ${OUTPUTDIR}/autoplot.pl --filetoplot ${RUNDIR}/plots/fort.61_transpose.txt --plotType elevation --plotdir ${RUNDIR}/plots --outputdir ${OUTPUTDIR} --timezone UTC --units si --stormname NAM --enstorm Forecast --cycleDIR $cycleDIR --datum NAVD88
   fi
   # plot wind speed data with gnuplot 
   if [[ -e ${RUNDIR}/plots/fort.72_transpose.txt ]]; then
      logMessage "Generating gnuplot script for $ENSTORM wind speed stations."
      perl ${OUTPUTDIR}/autoplot.pl --filetoplot ${RUNDIR}/plots/fort.72_transpose.txt --plotType windvelocity --plotdir ${RUNDIR}/plots --outputdir ${OUTPUTDIR} --timezone UTC --units si --stormname NAM  --enstorm Forecast --cycleDIR $cycleDIR --datum NAVD88
   fi
fi
# -----------------------------------------------------------------------------------
#                            G I S     K M Z      J P G 
# -----------------------------------------------------------------------------------
# name of bounding box for contour plots (see config_simple_gmt_pp.sh  for choices)
if [[ $stage -eq 1 ]]; then
   north=40.6         
   south=10.719124
   east=-59.94    
   west=-97.805957
fi
if [[ $stage -eq 2 ]]; then
   north=29.084346
   south=26.943526
   east=-80.059623
   west=-80.958714
fi
cd $mainDIR
FIGUREGENEXECUTABLE=FigureGen.x
logMessage "Generating 2D contour of stage $stage forecast results with following options: $RUNDIR $OUTPUTDIR $cycleDIR $HOSTNAME $ENSTORM $CONFIG $FIGUREGENEXECUTABLE $north $south $east $west $SYSLOG $stage"
#${OUTPUTDIR}/POSTPROC_KMZGIS/vslztn_contour.sh $RUNDIR $OUTPUTDIR $cycleDIR $HOSTNAME $ENSTORM $CONFIG $FIGUREGENEXECUTABLE $north $south $east $west $SYSLOG $stage
