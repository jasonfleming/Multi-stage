#!/bin/bash
# 
RUNDIR=$1
OUTPUTDIR=$2
cycleDIR=$3
ENSTORM=$4
CONFIG=$5
FIGUREGENEXECUTABLE=$6
SYSLOG=$7
stage=$8
#
. $CONFIG     
. ${mainDIR}/src/logging.sh
cd $RUNDIR             

# set path to the POSTPROC_KMZGIS directory
POSTPROC_DIR=$OUTPUTDIR/POSTPROC_KMZGIS

# OUTPUTPREFIX : set output filename prefix
OUTPUTPREFIX=${cycleDIR}.vis

# ######################################################################################
#                        .. JPG ..
#
JPGLOGFILE=$RUNDIR/jpg.log # log file for jpg-related info/errors
date >> $JPGLOGFILE
if [[ $FIGUREGENEXECUTABLE = "" ]]; then
   FIGUREGENEXECUTABLE=FigureGen.x
fi
# --------------------------------------------------------------------------------------
#   2D Contour of full domain (excluding bay of Main and Fundy)
# --------------------------------------------------------------------------------------
#
#			ANIMATION
#
mkdir $RUNDIR/Temp 2>> $JPGLOGFILE
if [[ $stage -eq 1 ]]; then
   FIGUREGENTEMPLATE_elev='full-ele-wind.inp'  
   FIGUREGENTEMPLATE_wave='full-hs-dir.inp'
else
   FIGUREGENTEMPLATE_elev='irl-ele-wind.inp'
   FIGUREGENTEMPLATE_wave='irl-hs-dir.inp' 
fi

# Copying control files, Labels, and other utilites
if [[ $stage -eq 1 ]]; then
   cp $OUTPUTDIR/POSTPROC_KMZGIS/FigGen/GIFs/Elev_MS.pal                 $RUNDIR 2>> $JPGLOGFILE
   cp $OUTPUTDIR/POSTPROC_KMZGIS/FigGen/GIFs/HS.pal                      $RUNDIR 2>> $JPGLOGFILE
   cp $OUTPUTDIR/POSTPROC_KMZGIS/FigGen/GIFs/fulldomain_background.txt   $RUNDIR 2>> $JPGLOGFILE
   cp $OUTPUTDIR/POSTPROC_KMZGIS/FigGen/GIFs/fulldomain_background.pgw   $RUNDIR 2>> $JPGLOGFILE
   cp $OUTPUTDIR/POSTPROC_KMZGIS/FigGen/GIFs/fulldomain_background.png   $RUNDIR 2>> $JPGLOGFILE
   cp $OUTPUTDIR/POSTPROC_KMZGIS/FigGen/GIFs/full-ele-wind.inp           $RUNDIR 2>> $JPGLOGFILE
   cp $OUTPUTDIR/POSTPROC_KMZGIS/FigGen/GIFs/full-hs-dir.inp             $RUNDIR 2>> $JPGLOGFILE
else
   cp $OUTPUTDIR/POSTPROC_KMZGIS/FigGen/GIFs/irl-ele-wind.inp            $RUNDIR 2>> $JPGLOGFILE
   cp $OUTPUTDIR/POSTPROC_KMZGIS/FigGen/GIFs/irl-hs-dir.inp              $RUNDIR 2>> $JPGLOGFILE
   cp $OUTPUTDIR/POSTPROC_KMZGIS/FigGen/GIFs/Elev_MS.pal                 $RUNDIR 2>> $JPGLOGFILE
   cp $OUTPUTDIR/POSTPROC_KMZGIS/FigGen/GIFs/HS.pal                      $RUNDIR 2>> $JPGLOGFILE
   cp $OUTPUTDIR/POSTPROC_KMZGIS/FigGen/GIFs/irl-background.txt          $RUNDIR 2>> $JPGLOGFILE
   cp $OUTPUTDIR/POSTPROC_KMZGIS/FigGen/GIFs/irl-background.pgw          $RUNDIR 2>> $JPGLOGFILE
   cp $OUTPUTDIR/POSTPROC_KMZGIS/FigGen/GIFs/irl-background.png          $RUNDIR 2>> $JPGLOGFILE
   cp $OUTPUTDIR/POSTPROC_KMZGIS/FigGen/GIFs/irl-labels.txt              $RUNDIR 2>> $JPGLOGFILE
fi

# Redirect to run directory
cd $RUNDIR

# Logging
logMessage "Generating 2D GIF contour for predicted surface elevation"

# Running the FigureGen for elevation and wind
mpirun -np $NCPU $POSTPROC_DIR/FigGen/${FIGUREGENEXECUTABLE} -I ${FIGUREGENTEMPLATE_elev} >> $JPGLOGFILE 2>&1 

# Running the FigureGen for elevation and wind
mpirun -np $NCPU $POSTPROC_DIR/FigGen/${FIGUREGENEXECUTABLE} -I ${FIGUREGENTEMPLATE_wave} >> $JPGLOGFILE 2>&1

date >> $JPGLOGFILE
if [[ $stage -eq 1 ]]; then
   convert -delay 18 FullElevWin*.jpg -loop 0 full_elev_wind.gif  &
   convert -delay 18 FullHsDir*.jpg   -loop 0 full_hs_dir.gif     &
else
   convert -delay 18 IRLElevWin*.jpg -loop 0 irl_elev_wind.gif    &
   convert -delay 18 IRLHsDir*.jpg   -loop 0 irl_hs_dir.gif       &
fi

# Cleaning
rm -rf Temp 2>> $JPGLOGFILE
rm *.jpg
# rm *.inp 
#
#
