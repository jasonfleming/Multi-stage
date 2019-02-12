#!/bin/bash
#
#########################################################
#
#                S U B    R O U T I N E
#
# Downloading SREF NMM (nmb) data
downloadSREF(){

    # Getting options
    ens=$1
    model=$2 
    fcst_hour=$3
    src=$4
    tmp=$5
    current_run=$6

    # Setting the URL
    url_con='http://www.ftp.ncep.noaa.gov/data/nccf/com/sref/prod/sref.'
    url_var=$today_date'/'$current_run'/pgrb/sref_'$model'.t'$current_run'z.pgrb132.'$ens'.f'$fcst_hour.grib2
    url=$url_con$url_var
    echo $url    
 
    # Creating folders for placing data
    mkdir $tmp/$ens'_'$model
    filename='sref_'$model'.t'$current_run'z.'$ens'.f'$fcst_hour.grib2
    wget $url -O $tmp/$ens'_'$model/$filename
}
# ================== E N D   O F   S U B R O U T I N E S ==================
# Options
CONFIG=$1
. ${CONFIG}

tmp=`pwd`/tmp/
src=`pwd`/src/
UVP=`pwd`/UVP/

# Defining ensemble names
ensemble=()
ensemble+=( ctl p1 p2 p3 p4 p5 p6 )                                            
ensemble+=(     n1 n2 n3 n4 n5 n6 )                        
lenE=${#ensemble[@]}

# Defining forecast hours
# Start from 006. We use 00-03 of NAM for nowcast. GEFS is used 
# for forecast. It should start from 06 up to 90
fcst_hou=()
fcst_hou+=( 03 06 09 12 15 18 21 24 27 30 33)
fcst_hou+=( 36 39 42 45 48 51 54 57 60 63)
fcst_hou+=( 66 69 72 75 78 81 84 87 )
lenF=${#fcst_hou[@]}

#
today_date=`date '+%Y%m%d'`
#today_date="20181025"

# removing previous index.htms
rm index.html*

# Getting the index.html
wget http://www.ftp.ncep.noaa.gov/data/nccf/com/sref/prod/sref.$today_date/

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

   # Get rid of old files
   rm -rf $tmp/*
   
   for (( hr=0; hr<${lenF}; hr++ )) ;
   do
         downloadSREF ${ensemble[0]} nmb ${fcst_hou[$hr]} $src $tmp $current &
         downloadSREF ${ensemble[1]} nmb ${fcst_hou[$hr]} $src $tmp $current &
         downloadSREF ${ensemble[2]} nmb ${fcst_hou[$hr]} $src $tmp $current &
         downloadSREF ${ensemble[3]} nmb ${fcst_hou[$hr]} $src $tmp $current &
         downloadSREF ${ensemble[4]} nmb ${fcst_hou[$hr]} $src $tmp $current &
         downloadSREF ${ensemble[5]} nmb ${fcst_hou[$hr]} $src $tmp $current &
         downloadSREF ${ensemble[6]} nmb ${fcst_hou[$hr]} $src $tmp $current &
         downloadSREF ${ensemble[7]} nmb ${fcst_hou[$hr]} $src $tmp $current &
         downloadSREF ${ensemble[8]} nmb ${fcst_hou[$hr]} $src $tmp $current &
         downloadSREF ${ensemble[9]} nmb ${fcst_hou[$hr]} $src $tmp $current &
         downloadSREF ${ensemble[10]} nmb ${fcst_hou[$hr]} $src $tmp $current &
         downloadSREF ${ensemble[11]} nmb ${fcst_hou[$hr]} $src $tmp $current &
         downloadSREF ${ensemble[12]} nmb ${fcst_hou[$hr]} $src $tmp $current & 
   done

   # Wait until all running jobs finish
   wait $(jobs -rp)

   # STARTING PROCESSING
   # Defining wind and press for genfort.x options
   press_options=()
   wind_options=()

   for dir in $(ls $tmp )
   do
       # Redirect to each member file
       cd $tmp/$dir/

       # Linking 
       ln -fs $mainDIR/utility/NAMtoOWI.pl
       ln -fs $mainDIR/input/ptFile.txt
       ln -fs $mainDIR/utility/PERL/Date

      ./NAMtoOWI.pl --ptFile ptFile.txt --namFormat grib2 --namType $dir --awipGridNumber 132 --dataDir $tmp/$dir/ --outDir $tmp/$dir/ --velocityMultiplier 1 --scriptDir $mainDIR --member sref &
   done

   # Get back to working dir
   cd $mainDIR/SREF

   # Wait until all running jobs finish
   wait $(jobs -rp)

   # Go through all members and add created NAM files as input for the fortran code
   for dir in $(ls $tmp )
   do
       cd $tmp/$dir/
       # Add the generated files to the ./genforts.x options
       press=`pwd`/`ls *.221`
       wind=`pwd`/`ls *.222`

       # Add the path to the beginning
       press_options+=($press)
       wind_options+=($wind)
   done

   # The fortran code reads press first, and then winds
   options="${press_options[*]} ${wind_options[*]}"

   # Get back to working dir
   cd $mainDIR/SREF

   # Linign the forts generating fortran code
   ln -fs $mainDIR/SREF/src/genforts.x $mainDIR/SREF/UVP/genforts.x

   # Redirect to the UVP where new fort.221/2 will be created 
   cd UVP/

   # Removing previous files (fortran write status is new)
   rm sref_*

   echo "Options for reading and processing nmb files are:"
   echo "${options[*]}"
   ./genforts.x ${options[*]}

   # Get back to working dir
   cd $mainDIR/SREF

   # Cleaning tmp
   rm -rf $tmp/*

# If new cycle found
fi
