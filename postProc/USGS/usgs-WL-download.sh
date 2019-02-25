#!/bin/bash
#
# Author
# Peyman Taeb Sep 2018
#
# Program description:
# Downloading data from USGS national water information system
#
# Supports: Water level 
#
# Usage:
# usgs-WL-download.sh <site name> <a fort.61 from 4 ensemble>                    
#
# ------------------------------------------------------------------------
# Options
site=$1
fort_61=$2

# For readibility
echo ""

# Station disctionary
if [[ $site = wabasso ]]; then
   site_no=02251800
elif [[ $site = haulovercanal ]]; then
   site_no=02248380
fi

# Info
echo "Info: Wrking on station $site ... "
   
# Getting year, month, day, hour, and minute of the current run
st_y=`cat $fort_61   | head -3 | tail -1 | cut -d' ' -f1 | cut -d'-' -f1`
st_m=`cat $fort_61   | head -3 | tail -1 | cut -d' ' -f1 | cut -d'-' -f2`
st_d=`cat $fort_61   | head -3 | tail -1 | cut -d' ' -f1 | cut -d'-' -f3 | cut -d',' -f1`
st_h=`cat $fort_61   | head -3 | tail -1 | cut -d' ' -f2 | cut -d':' -f1`                                
st_mm=`cat $fort_61   | head -3 | tail -1 | cut -d' ' -f2 | cut -d':' -f2`                               
echo "Info: Model-predicted water level starts at $st_h:$st_mm UTC on $st_m/$st_d/$st_y"

en_y=`cat $fort_61   | tail -1 | cut -d' ' -f1 | cut -d'-' -f1`
en_m=`cat $fort_61   | tail -1 | cut -d' ' -f1 | cut -d'-' -f2`
en_d=`cat $fort_61   | tail -1 | cut -d' ' -f1 | cut -d'-' -f3 | cut -d',' -f1`
en_h=`cat $fort_61   | tail -1 | cut -d' ' -f2 | cut -d'-' -f3 | cut -d',' -f2 | cut -d':' -f1`
en_mm=`cat $fort_61  | tail -1 | cut -d' ' -f2 | cut -d'-' -f3 | cut -d',' -f2 | cut -d':' -f2`
echo "Info: Model-predicted water level ends at   $en_h:$en_mm UTC on $en_m/$en_d/$en_y"

# Downloading some data to identify the time zone
begin_date_TZ=`date +%Y-%m-%d --date="$st_y-$st_m-$st_d"`
end_date_TZ=`date +%Y-%m-%d --date="$st_y-$st_m-$st_d"`
echo "Info: Downloading date from $begin_date_TZ to $end_date_TZ just to get the time zone"

# Initial download to find out the time zone
url="https://waterdata.usgs.gov/nwis/uv?cb_00065=on&format=rdb&site_no=$site_no&period=&begin_date=$begin_date_usgs&end_date=$end_date_usgs" 
wget $url -O raw-observed-$site-initial > /dev/null 2>&1

# Finding out the time zone of USGS data (EDT/EST)
identify_timezone=`tail -10 raw-observed-$site-initial | grep "EDT"`
if [[ ! -z $identify_timezone ]]; then
   echo "Info: Time zone is EDT in USGS data: GMT-4"
   time_zone="EDT"
   offset="4"
else
   echo "Info: Time zone is EST in USGS data: GMT-5"  
   time_zone="EST"
   # offset="5"  ! Not seem right
   offset=6
fi

# Download date not contain hour and min (not supported in the USGS website)
begin_date_plot=`date '+%Y-%m-%d %H:%M' --date="$begin_date_TZ "`
begin_date_download=`date '+%Y-%m-%d' --date="$begin_date_plot"`

# OBSERVATION END DATE IS NOW DATE
end_date_plot=`date '+%Y-%m-%d %H:%M'`
end_date_download=`date '+%Y-%m-%d'`

echo "Info: Observed data will be downloaded from the beginning of the validation cycle"
echo "      and ending some hours after the start time of the cycle:"
echo "      $begin_date_plot $time_zone  TO  $end_date_plot $time_zone"

# Downloading USGS data starting from 2 days before the start time of the current cycle
url="https://waterdata.usgs.gov/nwis/uv?cb_00065=on&format=rdb&site_no=$site_no&period=&begin_date=$begin_date_download&end_date=$end_date_download" 
wget $url -O raw-observed-$site 

# Trimming the observed starting from time 2 day ago
# First, deleting the metadata from the head of the file
# Second, There are two header following the meta data
# tail -n +3 deletes these two line.
sed -e '/#/d' raw-observed-$site  | tail -n +3 > trimmed-observed-$site

# Cleaning
rm raw-observed-$site-initial
rm raw-observed-$site
mv raw-observed-$site-trim-tail  trimmed-observed-$site

# Calling the fortran code to process data (calculating mean and applying sshag)
# Syntax
#       ./usgs_wl_process.x <trimmed file name > sshag
sshag=-0.22
./usgs_wl_process.x trimmed-observed-$site $sshag
echo "Info: Processed water level data created (fort.71)"

# Greping the end time of the downloaded data which is the time of
# the moment the plot is being generated. 
end_date=`tail -1 'trimmed-observed'-$site | awk '{print $3}'`
echo "end_date of trimmed data in EDT: $end_date"
end_time=`tail -1 'trimmed-observed'-$site | awk '{print $4}'`
echo "end_time of trimmed data in EDT: $end_time"
end_EDT="$end_date $end_time"
s=$end_EDT

# For no clear reason, the best match in terms of phase is obtained
# when Haul-over Canal time zone is assumed to be UTC
#if [[ $site = haulovercanal ]]; then
#   end_UTC=$end_EDT
#else
end_UTC=`date -d "${s:0:10} ${s:11:2} +$offset hour" '+%Y-%m-%d %H:%M'`
#fi

echo "end_UTC $end_UTC"
#

# Getting the length of trimmed file
len=`wc -l 'trimmed-observed'-$site | cut -d' ' -f1`

# I can't make +15 minutes work, so I create date/time in reverese order (last day to first day)
# and then re-order them later
# Creating reversed order of date and time in UTC for observed USGS
for (( i=0; i<${len}; i++ )) ;
do
   DATETIME=`date '+%Y-%m-%d %H:%M' --date="$end_UTC 15 minutes ago"`
   echo "$DATETIME:00 UTC" >>  DateTimeColumn_usgs_observed_UTC_$site
   end_UTC=$DATETIME
done
echo "Info: Date and time column created in UTC for observations"

# Re-order the date time 
sort  DateTimeColumn_usgs_observed_UTC_$site > DateTimeColumn_usgs_observed_UTC_srtd_$site

# Cleaning
rm DateTimeColumn_usgs_observed_UTC_$site
mv DateTimeColumn_usgs_observed_UTC_srtd_$site  DateTimeColumn_usgs_observed_UTC_$site

# Creating the final USGS observation file by pasting date/time and processed data
paste DateTimeColumn_usgs_observed_UTC_$site fort.71 > WL-$site-USGS2

# We get rid of the data that falls behind the start date of the validation cycle
# We need to redefine the parameter of start of the validation cylce to add the HH:MM
begin_date_cut=`date +%Y-%m-%d --date="$st_y-$st_m-$st_d $en_h:$en_mm"`
grep $begin_date_cut -A 1000 WL-$site-USGS2 > WL-$site-USGS

echo "Info: Final file containing a Date/Time in UTC and water level data at $site is created: WL-$site-USGS"
echo ""
echo "        D O N E        "
echo ""

# Cleaning
rm DateTimeColumn_usgs_observed_UTC_$site fort.71 trimmed-observed-$site raw-observed-$site

# 
exit
