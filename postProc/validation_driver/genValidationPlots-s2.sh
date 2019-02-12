#!/bin/bash
#
# Author:
#       Peyman Taeb 
#       October 2018
#
# As a component of Multistage-NAM-GEFS
#
# -----------------------------------------------------------------------
 
# Reading options
cycleDir=$1
main=$2
CONFIG=$3
SYSLOG=$4

# Calling loggins.sh
. ${CONFIG}
. $main/src/logging.sh
logMessage "Starting creating validation plots for state 2"

# Defining the path to the current cycle run
workDir=`pwd`/$cycleDir/
mkdir $workDir/validation_s2

# Defining the old cycle run before redirecting to the current cycle dir.
cycleDir_date="$(echo $cycleDir | cut -c1-8)"
cycleDir_time="$(echo $cycleDir | cut -c9-10)"

old_pred_date=`date +'%Y%m%d' -d "$cycleDir_date 2 days ago"`
old_pred="$old_pred_date$cycleDir_time"

# In case of missing the 2 days ago cycle, pick another cycle from 2 days ago
if [ ! -d $mainDIR/$ID/${old_pred} ]; then
   old_pred=`ls $mainDIR/$ID | grep $old_pred_date | head -1`
fi

logMessage "Appending prediction of cycle $old_pred"
old_pred_path=`pwd`/$old_pred

# Redirecting to current cycle dir
cd $workDir/validation_s2

# Linking fort.61_transpose.txt files from ensemble runs
# First, checking the existance. If an ensemble has not been
# set to performed, or crashed, the validation plot should
# be still created by using other runs' results.
# NAM
memb=()
if [ -e $workDir/nam/S2/plots/fort.61_transpose.txt ]; then
   ln -fs $workDir/nam/S2/plots/fort.61_transpose.txt             fort.61_nam
   memb+=( nam )
fi
# GEFS mean
if [ -e $workDir/GEFSmean/S2/plots/fort.61_transpose.txt ]; then
   ln -fs $workDir/GEFSmean/S2/plots/fort.61_transpose.txt        fort.61_GEFSmean
   memb+=( GEFSmean)      
fi
# GEFS mean
if [ -e $workDir/GEFSmeanPstd/S2/plots/fort.61_transpose.txt ]; then
   ln -fs $workDir/GEFSmeanPstd/S2/plots/fort.61_transpose.txt    fort.61_GEFSmeanPstd
   memb+=( GEFSmeanPstd )
fi
# GEFS mean
if [ -e $workDir/GEFSmeanMstd/S2/plots/fort.61_transpose.txt ]; then
   ln -fs $workDir/GEFSmeanMstd/S2/plots/fort.61_transpose.txt    fort.61_GEFSmeanMstd
   memb+=( GEFSmeanMstd )
fi
# SREFmean
if [ -e $workDir/SREFmean/S2/plots/fort.61_transpose.txt ]; then
   ln -fs $workDir/SREFmean/S2/plots/fort.61_transpose.txt        fort.61_SREFmean
   memb+=( SREFmean)
fi
# SREFmeanPstd
if [ -e $workDir/SREFmeanPstd/S2/plots/fort.61_transpose.txt ]; then
   ln -fs $workDir/SREFmeanPstd/S2/plots/fort.61_transpose.txt    fort.61_SREFmeanPstd
   memb+=( SREFmeanPstd )
fi
# SREFmeanMstd
if [ -e $workDir/SREFmeanMstd/S2/plots/fort.61_transpose.txt ]; then
   ln -fs $workDir/SREFmeanMstd/S2/plots/fort.61_transpose.txt    fort.61_SREFmeanMstd
   memb+=( SREFmeanMstd )
fi 
 
# Paste them into one
lenM=${#memb[@]}

#
j=0
echo "Info: Pasting member ${memb[0]}"
cp fort.61_${memb[0]} single_fort61_$j

for (( i=1; i<${lenM}; i++ )) ;
   do
   logMessage "Pasting member ${memb[$i]}"
   paste single_fort61_$j fort.61_${memb[$i]} > single_fort61_$i
   # Cleaning
   rm single_fort61_$j
   #
   j=`expr "$j" + 1`
   done

logMessage "Single_fort61 has been generated"
i=`expr "$i" - 1`
mv single_fort61_$i single_fort61

# Getting the prediction from 2 days ago
# Copying 
cp $old_pred_path/validation_s2/single_fort61 single_fort61_$old_pred

# Find the start time of the current cycle and 
date_cut=`head -3 fort.61_${memb[0]} | tail -1 | cut -d' ' -f1`
time_cut=`head -3 fort.61_${memb[0]} | tail -1 | cut -d' ' -f2`
datetime_cut="$date_cut $time_cut"

# Delete the lines from old run that overlap the current run
line_cut=`grep "${datetime_cut}" single_fort61_$old_pred`
sed "/${line_cut}/,\$d" single_fort61_$old_pred > single_fort61_old

# Downloading USGS data
# Linking 
ln -fs $main/postProc/USGS/usgs-WL-download.sh
ln -fs $main/postProc/USGS/usgs_wl_process.x

# Copying these two, we need to sed them later
cp  $main/postProc/USGS/template-wabasso.gp template-wabasso.gp 
cp  $main/postProc/USGS/template-hc.gp      template-hc.gp

./usgs-WL-download.sh   haulovercanal  single_fort61_old
./usgs-WL-download.sh   wabasso        single_fort61_old

# Finding max and min of observaion for the use in yrange of gnuplot
max=`cat WL-haulovercanal-USGS | cut -d' ' -f4 | sort -n | head -1`
min=`cat WL-haulovercanal-USGS | cut -d' ' -f4 | sort -n | tail -1`

margin_min=`echo "$min" / 10 | bc -l`
echo "$min" - "$margin_min" | bc -l > x-hc-line

margin_max=`echo "$max" / 10 | bc -l`
echo "$max" + "$margin_max" | bc -l >> x-hc-line

max=`cat WL-wabasso-USGS | cut -d' ' -f4 | sort -n | head -1`
min=`cat WL-wabasso-USGS | cut -d' ' -f4 | sort -n | tail -1`

margin_min=`echo "$min" / 10 | bc -l`
echo "$min" - "$margin_min" | bc -l > x-wabasso-line

margin_max=`echo "$max" / 10 | bc -l`
echo "$max" + "$margin_max" | bc -l >> x-wabasso-line

# Creating the line illustrating the cycle start time
# Date
head -3 fort.61_${memb[0]} | tail -1 | cut -d' ' -f1 >  dateline
head -3 fort.61_${memb[0]} | tail -1 | cut -d' ' -f1 >> dateline

#Time
head -3 fort.61_${memb[0]} | tail -1 | cut -d' ' -f2 >  timeline
head -3 fort.61_${memb[0]} | tail -1 | cut -d' ' -f2 >> timeline

#Zone
head -3 fort.61_${memb[0]} | tail -1 | cut -d' ' -f3 >  zoneline
head -3 fort.61_${memb[0]} | tail -1 | cut -d' ' -f3 >> zoneline

# Creating the line file
paste -d" " dateline timeline zoneline x-hc-line      > line-hc
paste -d" " dateline timeline zoneline x-wabasso-line > line-wa

# Cleaning
rm dateline timeline zoneline x-hc-line x-wabasso-line

# Writing Cycle number to gnuplot template
sed -i 's/%cycle%/'$cycleDir'/g'       template-hc.gp
sed -i 's/%oldcycle%/'$old_pred'/g'    template-hc.gp
sed -i 's/%cycle%/'$cycleDir'/g'       template-wabasso.gp
sed -i 's/%oldcycle%/'$old_pred'/g'    template-wabasso.gp

# Creating plots
gnuplot template-hc.gp
gnuplot template-wabasso.gp

# Converting - Creating in 200 dpi. PS files are stored and can
# be converted to higher quality JPG or other formats. 
convert -rotate 90 -density 200 Haulover_WL.ps Haulover_WL.jpg 
convert -rotate 90 -density 200 Wabasso_WL.ps  Wabasso_WL.jpg

# A little more cleaning
# We keep the rest for troubleshooting purposes. The remaining files
# along with other folder and files of this cyclewill be deteleted
# by postManaging.sh 5 days later
rm fort* swan* 

# Get back to where we were
cd -

# Notifying the users and sending validation plots
USERNAME="ptaeb2014@my.fit.edu rjweaver@fit.edu"
mail -s "WL & Hs validation at USGS, NOAA, and CPRG stations for $cycleDir" -a $workDir/validation_s2/Haulover_WL.jpg -a $workDir/validation_s2/Wabasso_WL.jpg -a $workDir/validation_s1/Trident_WL.jpg -a $workDir/validation_s1/CPRG_WL.jpg  -a $workDir/validation_s1/CPRG_HS.jpg -a $workDir/validation_s1/NOAA41113_HS.jpg -a $workDir/validation_s1/CPRG_Cur.jpg -a $workDir/validation_s1/Trident_speed.jpg  $USERNAME <<- EOF 

  Automatic notification from Multistage-NAM-GEFS
