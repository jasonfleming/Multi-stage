#!/bin/bash
#
# Processing the data that just has been downloaded for two domain; large and small
#
##############################
#
# Options
domain=$1

tmp=`pwd`/tmp/
src=`pwd`/src/
uv=`pwd`/uv_$domain/

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

# Defining the lon/lat of the corners of GEFS cells in which the IRL is resolved
# Using seq(ence) command of bash: $seq FIRST STEP LAST
if [ "$domain" == "IRL" ]; then
   # Box
   lat=(26.5  29.5)
   lon=(279  280)
fi
if [ "$domain" == "ec_large" ]; then
   # Box
   lat=(10 44)
   lon=(262 300)
fi

#
# Getting the length of lat/lon vector
lenlat=${#lat[@]}
lenlon=${#lon[@]}

i=0
#
# Processing grib file
for file in $(ls $tmp )
do
    # Extract the region we are interested by plugging start and end lat/long
    wgrib2 $tmp/$file -small_grib  ${lon[0]}:${lon[1]}  ${lat[0]}:${lat[1]}  $tmp/file.${domain}.tmp.grb2  
    wgrib2 $tmp/file.${domain}.tmp.grb2 -match 'UGRD' -spread  $tmp/u_${domain}_tmp$i.csv                             
    wgrib2 $tmp/file.${domain}.tmp.grb2 -match 'VGRD' -spread  $tmp/v_${domain}_tmp$i.csv                             
    wgrib2 $tmp/file.${domain}.tmp.grb2 -match 'PRES:surface' -spread  $tmp/press_${domain}_tmp$i.csv                
 
    #
    # Formatting 
    # (1) Subsituting comma by space (sort command likes spaces)
    sed -i 's/,/ /g' $tmp/u_${domain}_tmp$i.csv
    sed -i 's/,/ /g' $tmp/v_${domain}_tmp$i.csv
    sed -i 's/,/ /g' $tmp/press_${domain}_tmp$i.csv
           
    #
    # Cleaning
    mv $tmp/u_${domain}*     $uv/
    mv $tmp/v_${domain}*     $uv/
    mv $tmp/press_${domain}* $uv/
    rm $tmp/file.${domain}.tmp.grb2

    #
    cat $uv/u_${domain}_tmp$i.csv     >> $uv/u.srtd.csv
    cat $uv/v_${domain}_tmp$i.csv     >> $uv/v.srtd.csv
    cat $uv/press_${domain}_tmp$i.csv >> $uv/press.srtd.csv

    i=`expr "$i" + 1`
done  
 #
 # In the development process, I wanted to keep the header to
 # check if all ensemble runs and GEFS outputs at 29 time steps
 # are download and written into files.
 # Headers were fine, but some duplicates (shared corners of neighboring cells)
 # still exist because slightly different values were assigned to shared corners.
 # This might be due to floating round off error or something like this
 # where the same corner is assigned 2m/s by one cell, and 2.000001m/s
 # by the other cell. 
 # The genOWI.F90 takes care of this issue and remove these remaining duplicates.
 # The genOWI.F90 needs the u and v file has no header.
 # Removing headers:
 cat $uv/u.srtd.csv     | sed '/UGRD/d' > $uv/u.no_header.srtd.csv
 cat $uv/v.srtd.csv     | sed '/VGRD/d' > $uv/v.no_header.srtd.csv
 cat $uv/press.srtd.csv | sed '/PRES/d' > $uv/press.no_header.srtd.csv

 # 
 # Getting the temporal res from headers
 # might need some work here so that the script finds out the freq itself
 temp_freq="3"

 #
 # Getting the start time 
 timeHeader=`grep "d=" $uv/u.srtd.csv | head -1 | cut -d'=' -f2 | cut -d' ' -f1`
 s=$timeHeader

 # we won't use the 00-03. So the start time is 6 hours later
 starttime=`date -d "${s:0:8} ${s:8:2} +6 hour" '+%Y%m%d%H'`
 endtime=`date -d "${s:0:8} ${s:8:2} +90 hour" '+%Y%m%d%H'`

 #
 # Running the fortran program that process, format, and create input forcing files
 ln -fs $src/genOWI.x $uv/genOWI.x
 cd $uv

 #
 # Arguements: ensemble number, starttime, endtime
 echo "Info: start creating wind files with this options:"
 echo "      options: "
 echo "      ensemble number=$lenE starttime=$starttime endtime=$endtime temporal freq of wind/press=$temp_freq"
 ./genOWI.x  $lenE  $starttime  $endtime  $temp_freq 
 cd ..
 
 #
 # Organizing
 mv $uv/fort.2220 $uv/fort.222_mean_$domain
 mv $uv/fort.2221 $uv/fort.222_meanPstd_$domain
 mv $uv/fort.2222 $uv/fort.222_meanMstd_$domain

 mv $uv/fort.2230 $uv/fort.221_mean_$domain
 mv $uv/fort.2231 $uv/fort.221_meanPstd_$domain
 mv $uv/fort.2232 $uv/fort.221_meanMstd_$domain
 
