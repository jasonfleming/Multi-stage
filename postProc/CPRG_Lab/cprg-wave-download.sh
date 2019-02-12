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
      wget $url -O cprg-url-wave
      
      # Finding the water level 
      HS_ft=`grep "Significant" cprg-url-wave | head -1 | cut -d'>' -f5 | cut -d'<' -f1`

      # Converting to meter
      HS_m=`echo ''$HS_ft' * 0.3048' | bc -l`
      echo "INFO: HS is $HS_m meter"      

      # The first occurence has the wave data (head -1)
      timezone=`grep "Timestamp" cprg-url-wave  | tail -1 | cut -d'(' -f2 | cut -d')' -f1`
      timeLocal=`grep "Timestamp" cprg-url-wave  | head -1 | cut -d'>' -f5 | cut -d'<' -f1`

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
      HS_time="$time_utc $HS_m"
   
      # Appending to file
      echo $HS_time >> obs-cprg-HS   
 
      # sleep for 3 hours   
      sleep 10800
      
      # test
      # sleep 60     

      # Delete the previous url
      rm  cprg-url-wave
done

