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
#      ./cprg-wind-download.sh 
#
# ------------------------------------------------------------------------
# Options

# URL not change
url="https://research.fit.edu/wave-data/real-time-data/"

# Infinite loop
cntr=1
while [ $cntr -gt 0 ]; do
      # Downloading
      wget $url -O cprg-url-wind
      
      # Finding the wind speed in mph
      wind_mph=`grep "Wind Speed (mph)" cprg-url-wind | head -1 | cut -d'>' -f5 | cut -d'<' -f1`
      wind_dir=`grep "Wind Direction" cprg-url-wind   | head -1 | cut -d'>' -f7 | cut -d'<' -f1`

      # Converting to ms-1
      wind_ms=`echo ''$wind_mph' * 0.44704' | bc -l`
      echo "INFO: Wind Speed is $wind_ms m/s"      
 
      # The second occurence has the wind data (tail -1)
      timezone=`grep "Timestamp" cprg-url-wind  | tail -1 | cut -d'(' -f2 | cut -d')' -f1`
      timeLocal=`grep "Timestamp" cprg-url-wind  | tail -1 | cut -d'>' -f5 | cut -d'<' -f1`
   
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
      wind_time_dir="$time_utc $wind_ms $wind_dir"
   
      # Appending to file
      echo $wind_time_dir >> obs-cprg-wind   

      # sleep for 15 min    
      sleep 900  
done

