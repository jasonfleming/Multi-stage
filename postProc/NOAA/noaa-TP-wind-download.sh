#!/bin/bash
#
# Author
# Peyman Taeb Sep 2018
#
# Program description:
# Downloading data from NOAA tides and current websites
#
# Supports: Wind speed           
#
# Usage:
# ./download_WL_data.sh begin_date end_date datum station time_zone unit interval
# -------------------------------------------------------------------------------

# Options:
site=$1
fort_72=$2
unit=$3
time_zone=$4
interval=6            # in minutes: Available options: 6minutes or h (hour)

# Getting year, month, day, hour, and minute of the validation cycle (old cycle)
st_y=`cat $fort_72   | head -3 | tail -1 | cut -d' ' -f1 | cut -d'-' -f1`
st_m=`cat $fort_72   | head -3 | tail -1 | cut -d' ' -f1 | cut -d'-' -f2`
st_d=`cat $fort_72   | head -3 | tail -1 | cut -d' ' -f1 | cut -d'-' -f3 | cut -d',' -f1`
st_h=`cat $fort_72   | head -3 | tail -1 | cut -d' ' -f2 | cut -d':' -f1`
st_mm=`cat $fort_72  | head -3 | tail -1 | cut -d' ' -f2 | cut -d':' -f2`

# Constructing begin date and hour
begin_date=`date +'%Y%m%d' --date="$st_y$st_m$st_d"`
begin_hour=`date +'%H:%M' --date="$st_h:$st_mm"`

# End date and hour is the current moment
end_date=`date +'%Y%m%d'`
end_hour=`date +'%H:%M'`

# Constructing the url
urlMET="https://tidesandcurrents.noaa.gov/api/datagetter?product=wind&application=NOS.COOPS.TAC.MET&begin_date=$begin_date%20$begin_hour&end_date=$end_date%20$end_hour&station=$site&time_zone=$time_zone&units=$unit&interval=$interval&format=xml"

# Downloading data
wget $urlMET -O wind-$site-raw

# Formatting the raw file to include date hour speed direction
cat wind-$site-raw | grep -e "<ws t=" | sed  's/<ws t=//g' | sed 's/  s=/  /g' | sed 's/ d=/  /g' | sed -r 's/\S+//5' | sed -r 's/\S+//5' | sed -r 's/\S+//5' | sed -r 's/\S+//5' | sed 's/"/ /g' > wind-$site-trimmed

# Cleaning
#rm wind-$site-raw


