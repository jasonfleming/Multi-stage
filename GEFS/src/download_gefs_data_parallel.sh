#!/bin/bash
#
# Downloading gefs data using get_inv.pl and get_grib.pl

#########################################################
#
#                S U B    R O U T I N E
#
# Downloading GEFS data
downloadGEFS(){
    # Getting options
    ens=$1
    fcst_hour=$2
    src=$3
    tmp=$4
    current_run=$5

    #
    # Setting the URL
    url_con='http://www.ftp.ncep.noaa.gov/data/nccf/com/gens/prod/gefs.'
    url_var=$today_date'/'$current_run'/pgrb2ap5/'$ens'.t'$current_run'z.pgrb2a.0p50.f'$fcst_hour
    url=$url_con$url_var

    # 
    # Downloading
    perl $src/get_inv.pl $url.idx | egrep "(10 m above|PRES:surface)" | perl $src/get_grib.pl $url  $ens'.t'$current_run_$fcst_hour.grib2 >> logfile
	       
    # 
    # Moving the output to data dir
    mv $ens'.t'$current_run_$fcst_hour.grib2  $tmp
}
# ================== E N D   O F   S U B R O U T I N E S ==================
#
# Syntax: src/download  [domain: IRL/ec_large]
echo "Syntax: src/download  [domain: IRL/ec_large]"

tmp=`pwd`/tmp/
src=`pwd`/src/

#
# Defining ensemble names
ensemble=()
ensemble+=( gec00 gep01 gep02 gep03 gep04 gep05 gep06 )
ensemble+=( gep07 gep08 gep09 gep10 gep11 gep12 gep13 )
ensemble+=( gep14 gep15 gep16 gep17 gep18 gep19 gep20 )
lenE=${#ensemble[@]}

#
# Defining forecast hours
# Start from 006. We use 00-03 of NAM for nowcast. GEFS is used 
# for forecast. It should start from 06 up to 90
fcst_hou=()
fcst_hou+=( 006 009 012 015 018 021 024 027 030 033)
fcst_hou+=( 036 039 042 045 048 051 054 057 060 063)
fcst_hou+=( 066 069 072 075 078 081 084 087 090)
lenF=${#fcst_hou[@]}

#
today_date=`date '+%Y%m%d'`
#today_date="20181025"

# removing previous index.htms
rm index.html*

# Getting the index.html
wget http://www.ftp.ncep.noaa.gov/data/nccf/com/gens/prod/gefs.$today_date/

# Getting the existing cycles using a combination
# of text processing commands
cat index.html | grep -a "href" | cut -d'"' -f2 | sed '1d' > current.cycles

# to delete the old.cycles file of yesterday
# and create a new empty, for use at 00 cycle
line_current=`wc -l current.cycles | cut -d' ' -f1`
line_old=`wc -l old.cycles | cut -d' ' -f1`

# if [ $line_old > $line_current ]; then == wrong relational operator for numeric comparison
if [ $line_old -gt $line_current ]; then
   rm old.cycles
   touch old.cycles
fi

#
current_cycles=`cat current.cycles`
old_cycles=`cat old.cycles`
echo "$STARTDATETIME (INFO): Current cycles: $current_cycles, old cycles: $old_cycles" 

# Checking if it has been changed compared to old.cycle
# We want the last uploaded cycle
# If the system can't catch one cyle,
# there will be two cycles in the diff file,
# We want the last one!
diff_cycle=$(diff current.cycles old.cycles  | tail -1 |  cut -d'<' -f2 |  cut -d' ' -f2 | cut -d'/' -f1)
#

if [ ! -z "$diff_cycle" ]; then
   current=$diff_cycle 
   # current_run="00"
   # Waiting for all GEFS memebers to get uploaded
   # sleep 5400   
   cp current.cycles old.cycles
   
   for (( hr=0; hr<${lenF}; hr++ )) ;
   do
         downloadGEFS ${ensemble[0]} ${fcst_hou[$hr]} $src $tmp $current & 
         downloadGEFS ${ensemble[1]} ${fcst_hou[$hr]} $src $tmp $current & 
         downloadGEFS ${ensemble[2]} ${fcst_hou[$hr]} $src $tmp $current & 
         downloadGEFS ${ensemble[3]} ${fcst_hou[$hr]} $src $tmp $current & 
         downloadGEFS ${ensemble[4]} ${fcst_hou[$hr]} $src $tmp $current & 
         downloadGEFS ${ensemble[5]} ${fcst_hou[$hr]} $src $tmp $current & 
         downloadGEFS ${ensemble[6]} ${fcst_hou[$hr]} $src $tmp $current & 
         downloadGEFS ${ensemble[7]} ${fcst_hou[$hr]} $src $tmp $current & 
         downloadGEFS ${ensemble[8]} ${fcst_hou[$hr]} $src $tmp $current & 
         downloadGEFS ${ensemble[9]} ${fcst_hou[$hr]} $src $tmp $current & 
         downloadGEFS ${ensemble[10]} ${fcst_hou[$hr]} $src $tmp $current & 
         downloadGEFS ${ensemble[11]} ${fcst_hou[$hr]} $src $tmp $current & 
         downloadGEFS ${ensemble[12]} ${fcst_hou[$hr]} $src $tmp $current & 
         downloadGEFS ${ensemble[13]} ${fcst_hou[$hr]} $src $tmp $current & 
         downloadGEFS ${ensemble[14]} ${fcst_hou[$hr]} $src $tmp $current & 
         downloadGEFS ${ensemble[15]} ${fcst_hou[$hr]} $src $tmp $current & 
         downloadGEFS ${ensemble[16]} ${fcst_hou[$hr]} $src $tmp $current & 
         downloadGEFS ${ensemble[17]} ${fcst_hou[$hr]} $src $tmp $current & 
         downloadGEFS ${ensemble[18]} ${fcst_hou[$hr]} $src $tmp $current & 
         downloadGEFS ${ensemble[19]} ${fcst_hou[$hr]} $src $tmp $current & 
         downloadGEFS ${ensemble[20]} ${fcst_hou[$hr]} $src $tmp $current & 
   done
# 
else 
     echo "Error: new cycle not detected. Aborted"
     exit
fi

echo "sleeping 60 sec for probable unfinished downloads"
sleep 60
# Processing data by calling process_gefs.sh
$src/process_gefs.sh IRL      & PIDIOS=$!
$src/process_gefs.sh ec_large & PIDMIX=$!

# Move foreward when the one that takes longer finishes up
wait $PIDIOS
wait $PIDMIX

#
# cleaning
rm $uv*/u*
rm $uv*/v*
rm $uv*/pre*
# rm $uv*/genOWI.x
rm $uv*/fort.9*
rm $tmp/*

