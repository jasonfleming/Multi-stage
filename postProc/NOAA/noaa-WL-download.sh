#!/bin/bash
#
# Author
# Peyman Taeb Nov 2018
#
# Program description:
# Downloading data from NOAA tides and currents               
#
# Supports: Water level 
#
# Usage:
#      ./noaa-WL-download.sh config TridentPier for.61_nam MSL GMT meteric SSHAG<0.22> 
#
# ------------------------------------------------------------------------
# Options
site=$1
fort_61=$2
datum=$3
time_zone=$4
unit=$5
sshag=$6

# For readibility
echo ""

# Station disctionary
if [[ $site = TridentPier ]]; then
   site_no=8721604 
fi
   
# Getting year, month, day, hour, and minute of the current run
st_y=`cat $fort_61   | head -3 | tail -1 | cut -d' ' -f1 | cut -d'-' -f1`
st_m=`cat $fort_61   | head -3 | tail -1 | cut -d' ' -f1 | cut -d'-' -f2`
st_d=`cat $fort_61   | head -3 | tail -1 | cut -d' ' -f1 | cut -d'-' -f3 | cut -d',' -f1`
st_h=`cat $fort_61   | head -3 | tail -1 | cut -d' ' -f2 | cut -d':' -f1`                                
st_mm=`cat $fort_61   | head -3 | tail -1 | cut -d' ' -f2 | cut -d':' -f2`                               
echo "Info: Model-predicted water level starts at $st_h:$st_mm UTC on $st_m/$st_d/$st_y"

# Defining begin and end time and date for downloading
begin=`date +'%Y%m%d %H%M' --date="$st_y$st_m$st_d $st_h$st_mm 2 day ago"`
end=`date +'%Y%m%d %H%M'`                              
 
echo "Info: Downloading date from $begin to $end at $site"

# Breaking the begin date-time into date hour minutes
begin_date="$(echo $begin | cut -c1-8)"
begin_hour="$(echo $begin | cut -c10-11)"

# Breaking the end date time into date hour minutes
end_date="$(echo $end | cut -c1-8)"
end_hour="$(echo $end | cut -c10-11)"

echo "Info: Downloading date from $begin_date $begin_hour:00 to $end_date $end_hour:00 at $site"

# Interval of obs in min
interval=15

# Initial download to find out the time zone
urlWL="https://tidesandcurrents.noaa.gov/api/datagetter?product=predictions&application=NOS.COOPS.TAC.WL&begin_date=$begin_date%20$begin_hour:00&end_date=$end_date%20$end_hour:00&datum=$datum&station=$site_no&time_zone=$time_zone&units=$unit&interval=$interval&format=xml"

# Downloading
wget $urlWL -O WL-$site-raw

# formating downloded data
cat WL-$site-raw | cut -d'"' -f2,4 | sed  's/"/  /g' | grep "20" > WL-$site-NAVD88

# Applying SSHAG
awk -v n=$sshag '{print $1 " "  $2 " "  $3-n}'  WL-$site-NAVD88  > WL$site-MSL-obs
