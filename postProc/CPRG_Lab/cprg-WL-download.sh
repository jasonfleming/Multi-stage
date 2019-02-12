#!/bin/bash
#
# Author
# Peyman Taeb Nov 2018
#
# Program description:
# Downloading data from Coastal Processes Research Group (CPRG) Lab
#
# Supports: Water level
#
# Usage:
#      ./cprg-WL-download.sh 
#
# ------------------------------------------------------------------------
# Options

# URL not change
url="https://research.fit.edu/wave-data/real-time-data/"

# Infinite loop
cntr=1
while [ $cntr -gt 0 ]; do
      # Downloading
      wget $url -O cprg-url
      
      # Finding the water level 
      WL_ft=`grep "Water Level" cprg-url | head -1 | cut -d'>' -f5 | cut -d'<' -f1`

      # Converting to meter
      WL_m=`echo ''$WL_ft' * 0.3048' | bc -l`
      echo "INFO: water level is $WL_m meter"      
 
      # The second occurence has the water level data (tail -1)
      timezone=`grep "Timestamp" cprg-url  | tail -1 | cut -d'(' -f2 | cut -d')' -f1`
      timeLocal=`grep "Timestamp" cprg-url  | tail -1 | cut -d'>' -f5 | cut -d'<' -f1`
   
      if [[ $timezone = EDT ]]; then
         offset=4
      elif [[ $timezone = EST ]]; then 
         offset=5
      fi

      # Converting to UTC
      s=$timeLocal
      time_hour_UTC=`date  -d "${s:0:10} ${s:11:2}  +$offset hour"  '+%Y-%m-%d %H'`

      # Extracting the minute and second from local
      min_sec=`echo $timeLocal | echo $timeLocal | cut -c15-19`
      
      # Appending the minute and second to UTC     
      time_utc="$time_hour_UTC:$min_sec UTC"

      # Concentrating time and WL for easier writing files
      WL_time="$time_utc $WL_m"
   
      # Appending to file
      echo $WL_time >> obs-cprg

      # Running moving-minimum average
      ./moving_minimum_WL.x 
  
      # The output is fort.199, paste it to obs-cprg
      paste -d" " obs-cprg fort.199 > obs-cprg-prcsd
 
      # sleep for 15 minutes
      sleep 900
      
      # test
      # sleep 60     

      # Delete the previous url
      rm  cprg-url fort.199
done

