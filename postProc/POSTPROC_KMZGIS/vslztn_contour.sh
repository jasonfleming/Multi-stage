#!/bin/bash
# 
RUNDIR=$1
OUTPUTDIR=$2
cycleDIR=$3
HOSTNAME=$4
ENSTORM=$5
CONFIG=$6
FIGUREGENEXECUTABLE=$7   
NORTH=$8   
SOUTH=$9
EAST=${10}
WEST=${11}
SYSLOG=${12}
stage=${13}
#
# GENERAL SET UP
#
. $CONFIG # grab all static config info
. ${mainDIR}/src/logging.sh
cd $RUNDIR             
#
# set path to the POSTPROC_KMZGIS directory
POSTPROC_DIR=$OUTPUTDIR/POSTPROC_KMZGIS
# OUTPUTPREFIX : set output filename prefix
OUTPUTPREFIX=${cycleDIR}.vis
#
# ######################################################################################
#                        .. JPG ..
#   perl make_JPG.pl --storm 01 --year 2006 --adv 05 --n 30.5 --s 28.5 --e -88.5 --w -90.5 --outputprefix 01_2006_nhcconsensus_05
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
   FIGUREGENTEMPLATE=$OUTPUTDIR/POSTPROC_KMZGIS/FigGen/Elev_gif_s1.inp
else 
   FIGUREGENTEMPLATE=$OUTPUTDIR/POSTPROC_KMZGIS/FigGen/Elev_gif_s2.inp
fi
cp $POSTPROC_DIR/FigGen/Elev_asgs.pal $RUNDIR 2>> $JPGLOGFILE
cp $POSTPROC_DIR/FigGen/FIT.eps       $RUNDIR 2>> $JPGLOGFILE
cp $POSTPROC_DIR/FigGen/Labels.txt    $RUNDIR 2>> $JPGLOGFILE
cp $POSTPROC_DIR/FigGen/coast.dot.EFL.txt $RUNDIR 2>> $JPGLOGFILE
cd $RUNDIR
perl ${POSTPROC_DIR}/FigGen/make_JPG.pl --figuregen_template $FIGUREGENTEMPLATE --adv $cycleDIR --n $NORTH --s $SOUTH --e $EAST --w $WEST --outputprefix $OUTPUTPREFIX  2>> $JPGLOGFILE 2>&1
logMessage "Generating 2D GIF contour for predicted surface elevation"
mpirun -np $NCPU $POSTPROC_DIR/FigGen/${FIGUREGENEXECUTABLE} -I FigGen_${OUTPUTPREFIX}.inp >> $JPGLOGFILE 2>&1 
rm -rf Temp 2>> $JPGLOGFILE
date >> $JPGLOGFILE
convert -delay 18 *.jpg -loop 0 elev_wind.gif
rm *.jpg
rm *.inp # removing previous input files
#
#
#			Static  elevation
#	
# Use the default FigureGen template if it has not been specified
if [[ $stage -eq 1 ]]; then
   FIGUREGENTEMPLATE=$OUTPUTDIR/POSTPROC_KMZGIS/FigGen/MaxEle_s1.inp  
else
   FIGUREGENTEMPLATE=$OUTPUTDIR/POSTPROC_KMZGIS/FigGen/MaxEle_s2.inp   
fi
mkdir $RUNDIR/Temp 2>> $JPGLOGFILE
cp $POSTPROC_DIR/FigGen/Elev_asgs.pal $RUNDIR 2>> $JPGLOGFILE
cp $POSTPROC_DIR/FigGen/FIT.eps       $RUNDIR 2>> $JPGLOGFILE
cd $RUNDIR/
perl ${POSTPROC_DIR}/FigGen/make_JPG.pl --figuregen_template $FIGUREGENTEMPLATE --adv $cycleDIR --n $NORTH --s $SOUTH --e $EAST --w $WEST --outputprefix $OUTPUTPREFIX  2>> $JPGLOGFILE 2>&1
logMessage "Generating 2D contour for maximum predicted surface elevation"
mpirun -np $NCPU $POSTPROC_DIR/FigGen/${FIGUREGENEXECUTABLE} -I FigGen_${OUTPUTPREFIX}.inp >> $JPGLOGFILE 2>&1 
rm -rf Temp 2>> $JPGLOGFILE
date >> $JPGLOGFILE
rm *.inp # removing previous input files
#
#
#                       Static  Hs
#
# Use the default FigureGen template if it has not been specified
if [[ $stage -eq 1 ]]; then
   FIGUREGENTEMPLATE=$OUTPUTDIR/POSTPROC_KMZGIS/FigGen/MaxHS_s1.inp
else
   FIGUREGENTEMPLATE=$OUTPUTDIR/POSTPROC_KMZGIS/FigGen/MaxHS_s2.inp
fi
mkdir $RUNDIR/Temp 2>> $JPGLOGFILE
cp $POSTPROC_DIR/FigGen/wavht.pal     $RUNDIR 2>> $JPGLOGFILE
cp $POSTPROC_DIR/FigGen/FIT.eps       $RUNDIR 2>> $JPGLOGFILE
cd $RUNDIR/
perl ${POSTPROC_DIR}/FigGen/make_JPG.pl --figuregen_template $FIGUREGENTEMPLATE --adv $cycleDIR --n $NORTH --s $SOUTH --e $EAST --w $WEST --outputprefix $OUTPUTPREFIX  2>> $JPGLOGFILE 2>&1
logMessage "Generating 2D contour for maximum predicted Hs"
mpirun -np $NCPU $POSTPROC_DIR/FigGen/${FIGUREGENEXECUTABLE} -I FigGen_${OUTPUTPREFIX}.inp >> $JPGLOGFILE 2>&1
rm -rf Temp 2>> $JPGLOGFILE
date >> $JPGLOGFILE
rm *.inp # removing previous input files
