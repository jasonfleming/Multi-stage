#!/bin/bash
#
# Author
# Peyman Taeb Nov 2018
#
# Program description:
# Downloading wave data from NOAA. URL:
#   https://www.ndbc.noaa.gov/data/realtime2/<station number>.txt
#
# Usage:
#      ./noaa-wave-download.sh 
#
# Station info:
# Station 41113 - Cape Canaveral Nearshore, FL (143) 28.400 N 80.534 W (28°23'59" N 80°32'2" W)
# User-friendly website: https://www.ndbc.noaa.gov/station_page.php?station=41113&uom=E&tz=GMT
# Data access url: https://www.ndbc.noaa.gov/data/realtime2/41113.txt
# ------------------------------------------------------------------------
# Option
cycleDir=$1

# URL not change
site_no="41113"
url="https://www.ndbc.noaa.gov/data/realtime2/${site_no}.txt"

#
wget $url -O ${site_no}-wave-obs

#
date=`echo $cycleDir | cut -c1-8`
hr=`echo $cycleDir | cut -c9-10`

# Creating the date of 2 days ago
startdate=`date +'%Y%m%d' -d "$date 2 days ago"`
startedate_time="$startdate$hr"

# Formatting date of starting 2 days ago
yr=`echo $startedate_time | cut -c1-4`
mo=`echo $startedate_time | cut -c5-6`
dy=`echo $startedate_time | cut -c7-8`
hr=`echo $startedate_time | cut -c9-10`

# Grepping 2 days ago and keep data since 2 days ago
grep -B 1000 "$yr $mo $dy $hr" ${site_no}-wave-obs > ${site_no}-wave-obs-prcsd1

# remove the first two lines: header
sed '1,2d' ${site_no}-wave-obs-prcsd1 > ${site_no}-wave-obs-prcsd2

# Ordering; starting from the end that has the oldest data
tail -n1000 ${site_no}-wave-obs-prcsd2 | tac  > ${site_no}-wave-obs-prcsd3

# Create the obs file (date TIME zone waveH)
cat ${site_no}-wave-obs-prcsd3 | cut -d' ' -f1  > year
cat ${site_no}-wave-obs-prcsd3 | cut -d' ' -f2  > month
cat ${site_no}-wave-obs-prcsd3 | cut -d' ' -f3  > day 
cat ${site_no}-wave-obs-prcsd3 | cut -d' ' -f4  > hour 
cat ${site_no}-wave-obs-prcsd3 | cut -d' ' -f5  > min 
cat ${site_no}-wave-obs-prcsd3 | cut -d' ' -f16 > wave

paste -d"-" year month day > date
paste -d":" hour min > hr-min
paste -d" " date hr-min wave > ${site_no}-wave-obs-final

# Cleaning
rm ${site_no}-wave-obs-p* ${site_no}-wave-obs year month day hour min wave date hr-min 

