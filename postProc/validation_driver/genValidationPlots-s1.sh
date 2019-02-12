#1/bin/bash
#
# Author:
#       Peyman Taeb 
#       October 2018
#
# As a component of Multistage-NAM-GEFS
# -----------------------------------------------------------------------
 
# Reading options
cycleDir=$1
main=$2
CONFIG=$3
SYSLOG=$4

# Calling loggins.sh
. $CONFIG
. ${main}/src/logging.sh
logMessage "Starting creating validation plots for stage 1"

# Defining the path to the current cycle run
workDir=`pwd`/$cycleDir/
mkdir $workDir/validation_s1

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
cd $workDir/validation_s1

# Linking fort.61_transpose.txt files from ensemble runs
# First, checking the existance. If an ensemble has not been
# set to performed, or crashed, the validation plot should
# be still created by using other runs' results.
# NAM

# Array of station outputs
st_out=( fort.61 fort.62 fort.72 fort.72_dir swan.61 )
lenST=${#st_out[@]}

memb=()
for (( i=0; i<${lenST}; i++ )) ;
do
   # NAM 
   ln -fs $workDir/nam/S1/plots/${st_out[$i]}_transpose.txt           ${st_out[$i]}_nam
   memb+=( nam )
 
   # GEFS mean
   ln -fs $workDir/GEFSmean/S1/plots/${st_out[$i]}_transpose.txt      ${st_out[$i]}_GEFSmean
   memb+=( GEFSmean)      

   # GEFS meanPstd
   ln -fs $workDir/GEFSmeanPstd/S1/plots/${st_out[$i]}_transpose.txt  ${st_out[$i]}_GEFSmeanPstd
   memb+=( GEFSmeanPstd )

   # GEFS meanMstd
   ln -fs $workDir/GEFSmeanMstd/S1/plots/${st_out[$i]}_transpose.txt  ${st_out[$i]}_GEFSmeanMstd
   memb+=( GEFSmeanMstd ) 
   
   # GEFS SREFmean
   ln -fs $workDir/SREFmean/S1/plots/${st_out[$i]}_transpose.txt      ${st_out[$i]}_SREFmean
   memb+=( SREFmean)

   # GEFS SREFmeanPstd
   ln -fs $workDir/SREFmeanPstd/S1/plots/${st_out[$i]}_transpose.txt  ${st_out[$i]}_SREFmeanPstd
   memb+=( SREFmeanPstd )

   # GEFS SREFmeanMstd
   ln -fs $workDir/SREFmeanMstd/S1/plots/${st_out[$i]}_transpose.txt  ${st_out[$i]}_SREFmeanMstd
   memb+=( SREFmeanMstd )
done

# Get rid of 0 column in swan.61_ files
sed -i -r 's/\S+//5' swan.61_*
sed -i -r 's/\S+//6' swan.61_*

# Paste them into one
lenM=${#memb[@]}

#
j=0
echo "Info: Pasting member ${memb[0]}"
cp fort.61_${memb[0]}     single_fort61_$j
cp fort.62_${memb[0]}     single_fort62_$j
cp fort.72_${memb[0]}     single_fort72_$j
cp fort.72_dir_${memb[0]} single_fort72_dir_$j
cp swan.61_${memb[0]}     single_swan61_$j

for (( i=1; i<${lenM}; i++ )) ;
   do
   logMessage "Pasting member ${memb[$i]}"
   paste single_fort61_$j     fort.61_${memb[$i]} >     single_fort61_$i
   paste single_fort62_$j     fort.62_${memb[$i]} >     single_fort62_$i
   paste single_fort72_$j     fort.72_${memb[$i]} >     single_fort72_$i
   paste single_fort72_dir_$j fort.72_dir_${memb[$i]} > single_fort72_dir_$i
   paste single_swan61_$j     swan.61_${memb[$i]} >     single_swan61_$i
   # Cleaning
   rm single_fort61_$j
   rm single_fort62_$j
   rm single_fort72_$j
   rm single_fort72_dir_$j
   rm single_swan61_$j
   #
   j=`expr "$j" + 1`
   done

logMessage "Single_fort6/7-1/2 and Single_swan61 have been generated"
i=`expr "$i" - 1`
mv single_fort61_$i     single_fort61
mv single_fort62_$i     single_fort62
mv single_fort72_$i     single_fort72
mv single_fort72_dir_$i single_fort72_dir
mv single_swan61_$i     single_swan61

# Getting the prediction from 3 days ago
# Copying
cp $old_pred_path/validation_s1/single_fort61     single_fort61_$old_pred
cp $old_pred_path/validation_s1/single_fort62     single_fort62_$old_pred
cp $old_pred_path/validation_s1/single_fort72     single_fort72_$old_pred
cp $old_pred_path/validation_s1/single_fort72_dir single_fort72_dir_$old_pred
cp $old_pred_path/validation_s1/single_swan61     single_swan61_$old_pred

# WL: Find the start time of the current cycle 
date_cut=`head -3 fort.61_${memb[0]} | tail -1 | cut -d' ' -f1`
time_cut=`head -3 fort.61_${memb[0]} | tail -1 | cut -d' ' -f2`
datetime_cut="$date_cut $time_cut"

# WL: Delete the lines from old run that overlap the current run
line_cut=`grep "${datetime_cut}" single_fort61_$old_pred`
sed "/${line_cut}/,\$d" single_fort61_$old_pred > single_fort61_old

# Current: Find the start time of the current cycle
date_cut=`head -3 fort.62_${memb[0]} | tail -1 | cut -d' ' -f1`
time_cut=`head -3 fort.62_${memb[0]} | tail -1 | cut -d' ' -f2`
datetime_cut="$date_cut $time_cut"

# Current: Delete the lines from old run that overlap the current run
line_cut=`grep "${datetime_cut}" single_fort62_$old_pred`
sed "/${line_cut}/,\$d" single_fort62_$old_pred > single_fort62_old

# Current: Delete the lines from old run that overlap the current run
line_cut=`grep "${datetime_cut}" single_fort72_$old_pred`
sed "/${line_cut}/,\$d" single_fort72_$old_pred >     single_fort72_old

# Current: Delete the lines from old run that overlap the current run
line_cut=`grep "${datetime_cut}" single_fort72_dir_$old_pred`
sed "/${line_cut}/,\$d" single_fort72_dir_$old_pred > single_fort72_dir_old

# HS: Find the start time of the current cycle (different output time step)
date_cut=`head -3 swan.61_${memb[0]} | tail -1 | cut -d' ' -f1`
time_cut=`head -3 swan.61_${memb[0]} | tail -1 | cut -d' ' -f2`
datetime_cut="$date_cut $time_cut"

# HS: Delete the lines from old run that overlap the current run
line_cut=`grep "${datetime_cut}" single_swan61_$old_pred`
sed "/${line_cut}/,\$d" single_swan61_$old_pred > single_swan61_old

############################# N O A A ##################################
#
#                     W A T E R      L E V E L
#                   T R I D E N T     P I E R
#
# Downloading USGS data
# Linking 
ln -fs $main/postProc/NOAA/noaa-WL-download.sh

# Copying these two, we need to sed them later
cp  $main/postProc/NOAA/template-TP-WL.gp      template-TP-WL.gp

# Running the script that downloads obs, note that stage one is on MSL
logMessage "Downloading obs from NOAA with options: station=TridentPier fort.61_${memb[0]} datum=MSL time zone=GMT UNIT=metric SSHAG=0.0"
./noaa-WL-download.sh TridentPier fort.61_${memb[0]} MSL GMT metric "0"

# Finding max and min of observaion for the use in yrange of gnuplot
max=`cat WLTridentPier-MSL-obs | cut -d' ' -f3 | sort -n | head -1`
min=`cat WLTridentPier-MSL-obs | cut -d' ' -f3 | sort -n | tail -1`

margin_min=`echo "$min" / 10 | bc -l`
echo "$min" - "$margin_min" | bc -l > x-TP-line

margin_max=`echo "$max" / 10 | bc -l`
echo "$max" + "$margin_max" | bc -l >> x-TP-line

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
paste -d" " dateline timeline zoneline x-TP-line      > line-TP

# Cleaning
rm dateline timeline zoneline x-TP-line

# Writing Cycle number to gnuplot template
sed -i 's/%cycle%/'$cycleDir'/g'    template-TP-WL.gp
sed -i 's/%oldcycle%/'$old_pred'/g' template-TP-WL.gp

# Creating plots
gnuplot template-TP-WL.gp

# Converting-Creating in 200 dpi. PS files are stored and can 
# be converted to higher quality JPG or other formats.
convert -rotate 90 -density 200  Trident_WL.ps Trident_WL.jpg

#--------------------------------------------------------------------
#                      W I N D    S P E E D    
#                   T R I D E N T     P I E R
#
# Downloading USGS data
# Linking 
ln -fs $main/postProc/NOAA/noaa-TP-wind-download.sh

# Copying gnuplot input
cp  $main/postProc/NOAA/template-noaa-TP-wind-speed.gp template-noaa-TP-wind-speed.gp

# Running the script that downloads obs, note that stage one is on MSL
logMessage "Downloading obs from NOAA with options: station=TridentPier single_fort72_old Unit=metric time zone=GMT"
./noaa-TP-wind-download.sh 8721604 single_fort72_old metric GMT

# Finding max and min of observaion for the use in yrange of gnuplot
min=`cat wind-8721604-trimmed | cut -d' ' -f7 | sort -n | head -1`
max=`cat wind-8721604-trimmed | cut -d' ' -f7 | sort -n | tail -1`

margin_min=`echo "$min" / 10 | bc -l`
if [ ! -z $argin_min ]; then
   echo "$min" - "$margin_min" | bc -l > x-TP-line 
else
   echo 0 > x-TP-line
fi

margin_max=`echo "$max" / 10 | bc -l`
echo "$max" + "$margin_max" | bc -l >> x-TP-line

# Creating the line illustrating the cycle start time
# Date
head -3 fort.72_${memb[0]} | tail -1 | cut -d' ' -f1 >  dateline
head -3 fort.72_${memb[0]} | tail -1 | cut -d' ' -f1 >> dateline

#Time
head -3 fort.72_${memb[0]} | tail -1 | cut -d' ' -f2 >  timeline
head -3 fort.72_${memb[0]} | tail -1 | cut -d' ' -f2 >> timeline

#Zone
head -3 fort.72_${memb[0]} | tail -1 | cut -d' ' -f3 >  zoneline
head -3 fort.72_${memb[0]} | tail -1 | cut -d' ' -f3 >> zoneline

# Creating the line file
paste -d" " dateline timeline zoneline x-TP-line      > line-TP-wind

# Cleaning
rm dateline timeline zoneline x-TP-line

# Writing Cycle number to gnuplot template
sed -i 's/%cycle%/'$cycleDir'/g'    template-noaa-TP-wind-speed.gp
sed -i 's/%oldcycle%/'$old_pred'/g' template-noaa-TP-wind-speed.gp

# Creating plots
gnuplot template-noaa-TP-wind-speed.gp

# Converting - Creating in 200 dpi. PS files are stored and can
# be converted to higher quality JPG or other formats. 
convert -rotate 90 -density 200 Trident_speed.ps Trident_speed.jpg

#--------------------------------------------------------------------
#                   W I N D    D I R E C T I O N 
#                   T R I D E N T     P I E R
#

# Copying gnuplot input
cp  $main/postProc/NOAA/template-noaa-TP-wind-dir.gp template-noaa-TP-wind-dir.gp    

# Finding max and min of observaion for the use in yrange of gnuplot
min=`cat wind-8721604-trimmed | cut -d' ' -f11 | sort -n | head -1`
max=`cat wind-8721604-trimmed | cut -d' ' -f11 | sort -n | tail -1`

margin_min=`echo "$min" / 10 | bc -l`
if [ ! -z $argin_min ]; then
   echo "$min" - "$margin_min" | bc -l > x-TP-line 
else
   echo 0 > x-TP-line
fi

margin_max=`echo "$max" / 10 | bc -l`
echo "$max" + "$margin_max" | bc -l >> x-TP-line

# Creating the line illustrating the cycle start time
# Date
head -3 fort.72_${memb[0]} | tail -1 | cut -d' ' -f1 >  dateline
head -3 fort.72_${memb[0]} | tail -1 | cut -d' ' -f1 >> dateline

#Time
head -3 fort.72_${memb[0]} | tail -1 | cut -d' ' -f2 >  timeline
head -3 fort.72_${memb[0]} | tail -1 | cut -d' ' -f2 >> timeline

#Zone
head -3 fort.72_${memb[0]} | tail -1 | cut -d' ' -f3 >  zoneline
head -3 fort.72_${memb[0]} | tail -1 | cut -d' ' -f3 >> zoneline

# Creating the line file
paste -d" " dateline timeline zoneline x-TP-line      > line-TP-dir 

# Cleaning
rm dateline timeline zoneline x-TP-line

# Creating plots
gnuplot template-noaa-TP-wind-dir.gp

# Converting - Creating in 200 dpi. PS files are stored and can
# be converted to higher quality JPG or other formats. 
convert -rotate 90 -density 200 Trident_dir.ps Trident_dir.jpg

# MERGE WIND SPEED AND DIR PLOTS
convert Trident_speed.jpg Trident_dir.jpg -append Trident_Wind.jpg

# -------------------------------------------------------------------
#                                
#       S I G N I F I C A N T     W A V E    H E I G H T S (HS)
#            N O A A   ST# 41113 -- Canaveral Nearshore
#
# Coppying obs and template
cp $main/postProc/NOAA/template-noaa-HS.gp  template-noaa-HS.gp

# Running the noaa Buoy wave data scritp
cd $main/postProc/NOAA/
./noaa-wave-download.sh $cycleDir
cd -
cp $main/postProc/NOAA/41113-wave-obs-final 41113-wave-obs-final

# Finding max and min of observaion for the use in yrange of gnuplot
max=`cat 41113-wave-obs-final  | awk '{ print $3 }' | sort -n | head -1`
min=`cat 41113-wave-obs-final  | awk '{ print $3 }' | sort -n | tail -1`

echo "$min" >  x-noaa-line
echo "$max" >> x-noaa-line

# Creating the line illustrating the cycle start time
# Date
head -3 swan.61_${memb[0]} | tail -1 | cut -d' ' -f1 >  dateline
head -3 swan.61_${memb[0]} | tail -1 | cut -d' ' -f1 >> dateline

#Time
head -3 swan.61_${memb[0]} | tail -1 | cut -d' ' -f2 >  timeline
head -3 swan.61_${memb[0]} | tail -1 | cut -d' ' -f2 >> timeline

#Zone
head -3 swan.61_${memb[0]} | tail -1 | cut -d' ' -f3 >  zoneline
head -3 swan.61_${memb[0]} | tail -1 | cut -d' ' -f3 >> zoneline

# Creating the line file
paste -d" " dateline timeline zoneline x-noaa-line      > line-noaa-HS

# Cleaning
rm dateline timeline zoneline x-noaa-line        

# Writing Cycle number to gnuplot template
sed -i 's/%cycle%/'$cycleDir'/g'    template-noaa-HS.gp
sed -i 's/%oldcycle%/'$old_pred'/g' template-noaa-HS.gp

# Creating plots
gnuplot template-noaa-HS.gp

# Converting  - Creating in 200 dpi. PS files are stored and can
# be converted to higher quality JPG or other formats.
convert -rotate 90 -density 200 NOAA41113_HS.ps NOAA41113_HS.jpg

######################## COASTAL PROCESS RESEARCH GROUP LAB #############################
#
#                            W A T E R      L E V E L 
#
# Getting data of downloaded obs from todays ago 00:00:00 HH:MM:SS always!
datestart=`date +'%Y-%m-%d 00:15:00' -d "2 days ago"`

# Development
# datestart="2018-11-07 02:30:00"

# Coppying obs and template
cp $main/postProc/CPRG_Lab/template-cprg-WL.gp  template-cprg-WL.gp
cp $main/postProc/CPRG_Lab/obs-cprg-prcsd       obs-cprg-entire

# Greping the start date and following lines
grep -A 1000 "$datestart" obs-cprg-entire > obs-cprg-trim

# Get rid of -99999.0000 generated by moving minimum filter
sed -i 's/-99999.0000/ /g'    obs-cprg-trim

# Finding max and min of observaion for the use in yrange of gnuplot
max=`cat obs-cprg-trim  | awk '{ print $5 }' | sort -n | head -1`
min=`cat obs-cprg-trim  | awk '{ print $5 }' | sort -n | tail -3 | head -1`

# For now
max=0.5
min=-0.5

margin_min=`echo "$min" / 10 | bc -l`
echo "$min" - "$margin_min" | bc -l > x-cprg-line

margin_max=`echo "$max" / 10 | bc -l`
echo "$max" + "$margin_max" | bc -l >> x-cprg-line

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
paste -d" " dateline timeline zoneline x-cprg-line      > line-cprg

# Cleaning
rm dateline timeline zoneline x-cprg-line obs-cprg new-obs-cprg

# Writing Cycle number to gnuplot template
sed -i 's/%cycle%/'$cycleDir'/g'    template-cprg-WL.gp
sed -i 's/%oldcycle%/'$old_pred'/g' template-cprg-WL.gp

# Creating plots
gnuplot template-cprg-WL.gp

# Converting
convert -rotate 90 -density 200 CPRG_WL.ps CPRG_WL.jpg

# -------------------------------------------------------------------------
#
#             S I G N I F I C A N T      W A V E    H E I G H T S 
#
# Getting data of downloaded obs from 2 days ago 00:00:00 HH:MM:SS always!
datestart=`date +'%Y-%m-%d 02:00:00' -d "2 days ago"`

# Development
# datestart="2018-11-07 02:30:00"

# Coppying obs and template
cp $main/postProc/CPRG_Lab/template-cprg-HS.gp  template-cprg-HS.gp
cp $main/postProc/CPRG_Lab/obs-cprg-HS          obs-cprg-HS-entire

# Greping the start date and following lines
grep -A 1000 "$datestart" obs-cprg-HS-entire > obs-cprg-HS

# Finding max and min of observaion for the use in yrange of gnuplot
max=`cat obs-cprg-HS  | awk '{ print $4 }' | sort -n | head -1`
min=`cat obs-cprg-HS  | awk '{ print $4 }' | sort -n | tail -1`

echo "$min" >  x-cprg-line
echo "$max" >> x-cprg-line

# Creating the line illustrating the cycle start time
# Date
head -3 swan.61_${memb[0]} | tail -1 | cut -d' ' -f1 >  dateline
head -3 swan.61_${memb[0]} | tail -1 | cut -d' ' -f1 >> dateline

#Time
head -3 swan.61_${memb[0]} | tail -1 | cut -d' ' -f2 >  timeline
head -3 swan.61_${memb[0]} | tail -1 | cut -d' ' -f2 >> timeline

#Zone
head -3 swan.61_${memb[0]} | tail -1 | cut -d' ' -f3 >  zoneline
head -3 swan.61_${memb[0]} | tail -1 | cut -d' ' -f3 >> zoneline

# Creating the line file
paste -d" " dateline timeline zoneline x-cprg-line      > line-cprg-HS

# Cleaning
rm dateline timeline zoneline x-cprg-line obs-cprg-HS-entire       

# Writing Cycle number to gnuplot template
sed -i 's/%cycle%/'$cycleDir'/g'    template-cprg-HS.gp
sed -i 's/%oldcycle%/'$old_pred'/g' template-cprg-HS.gp

# Creating plots
gnuplot template-cprg-HS.gp

# Converting - Creating in 200 dpi. PS files are stored and can
# be converted to higher quality JPG or other formats.
convert -rotate 90 -density 200 CPRG_HS.ps CPRG_HS.jpg

# -------------------------------------------------------------------------
#
#                  Current velocity and direction                      
#
# Coppying obs and template
cp $main/postProc/CPRG_Lab/template-cprg-cur.gp template-cprg-cur.gp
cp $main/postProc/CPRG_Lab/obs-cprg-current     obs-cprg-cur-entire

# Getting data of downloaded obs from 2 days ago 00:00:00 HH:MM:SS always!
datestart=`date +'%Y-%m-%d 02:00:00' -d "2 days ago"`

# Greping the start date and following lines
grep -A 1000 "$datestart" obs-cprg-cur-entire > obs-cprg-cur

# Finding max and min of observaion for the use in yrange of gnuplot
max=`cat obs-cprg-cur | awk '{ print $4 }' | sort -n | head -1`
min=`cat obs-cprg-cur | awk '{ print $4 }' | sort -n | tail -1`

echo "$min" >  x-cprg-line
echo "$max" >> x-cprg-line

# Creating the line illustrating the cycle start time
# Date
head -3 fort.62_${memb[0]} | tail -1 | cut -d' ' -f1 >  dateline
head -3 fort.62_${memb[0]} | tail -1 | cut -d' ' -f1 >> dateline

#Time
head -3 fort.62_${memb[0]} | tail -1 | cut -d' ' -f2 >  timeline
head -3 fort.62_${memb[0]} | tail -1 | cut -d' ' -f2 >> timeline

#Zone
head -3 fort.62_${memb[0]} | tail -1 | cut -d' ' -f3 >  zoneline
head -3 fort.62_${memb[0]} | tail -1 | cut -d' ' -f3 >> zoneline

# Creating the line file
paste -d" " dateline timeline zoneline x-cprg-line      > line-cprg-cur

# Cleaning
rm dateline timeline zoneline x-cprg-line        

# Writing Cycle number to gnuplot template
sed -i 's/%cycle%/'$cycleDir'/g'    template-cprg-cur.gp
sed -i 's/%oldcycle%/'$old_pred'/g' template-cprg-cur.gp

# Creating plots
gnuplot template-cprg-cur.gp

# Converting - Creating in 200 dpi. PS files are stored and can
# be converted to higher quality JPG or other formats.
convert -rotate 90 -density 200 CPRG_Cur.ps CPRG_Cur.jpg

# A little more cleaning
# We keep the rest for troubleshooting purposes. The remaining files
# along with other folder and files of this cyclewill be deteleted
# by postManaging.sh 5 days later
rm fort* swan*

# ------------------------------------------------------------------------
#
#
USERNAME="ptaeb2014@my.fit.edu"
mail -s "Validation plots at Trident Pier NOAA stations for $cycleDir" -a $workDir/validation_s1/Trident_WL.jpg -a $workDir/validation_s1/CPRG_WL.jpg  -a $workDir/validation_s1/CPRG_HS.jpg -a $workDir/validation_s1/NOAA41113_HS.jpg  -a   $workDir/validation_s1/CPRG_Cur.jpg -a $workDir/validation_s1/Trident_Wind.jpg  $USERNAME <<- EOF 

  Automatic notification from Multistage-NAM-GEFS
