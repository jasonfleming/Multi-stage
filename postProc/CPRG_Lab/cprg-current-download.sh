#!/bin/bash
#
# Author
# Peyman Taeb Nov 2018
#
# Program description:
# Downloading data from Coastal Processes Research Group (CPRG) Lab
#
# Supports: Depth Average Current Speed and Direction 
#
# Usage:
#      ./cprg-current-download.sh 
#
# ------------------------------------------------------------------------
# Options

# URL not change
url="https://research.fit.edu/wave-data/real-time-data/"

# Infinite loop
cntr=1
while [ $cntr -gt 0 ]; do
      # Downloading
      wget $url -O cprg-url-cur
      
      # Finding the water level 
      cu_kts=`grep "Depth Averaged Current Speed (kts)" cprg-url-cur | head -1 | cut -d'>' -f5 | cut -d'<' -f1`
      cu_dir=`grep "Depth Averaged Current Direction" cprg-url-cur | cut -d'>' -f7 | cut -d'<' -f1`

      # Converting to ms-1
      cu_ms=`echo ''$cu_kts' * 0.514444' | bc -l`
      echo "INFO: Depth Averaged Current Speed is $cu_ms m/s"      
 
      # The first occurence has the current data (head -1)
      timezone=`grep "Timestamp" cprg-url-cur  | tail -1 | cut -d'(' -f2 | cut -d')' -f1`
      timeLocal=`grep "Timestamp" cprg-url-cur  | head -1 | cut -d'>' -f5 | cut -d'<' -f1`
 
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
      cu_time_dir="$time_utc $cu_ms $cu_dir"
   
      # Appending to file
      echo $cu_time_dir >> obs-cprg-current

      # sleep for 3 hours   
      sleep 10800
done

