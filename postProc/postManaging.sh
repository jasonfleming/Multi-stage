#!/bin/bash

# Options
SYSLOG=$1
config=$2
cycleDir=$3

# Getting variables from config
. ${config}
. ${mainDIR}/src/logging.sh

# ------------------------------------------------------------
#                         Archiving

cd $mainDIR/$ID/$cycleDir

cd validation_s1
for file in `ls *.ps`
do 
  # Folder name is the same as PS file excluding .ps
  # The following command trim the last 3 character: .ps
  folder=`echo "${file::-3}"`
  echo $file
  cp $file $mainDIR/archive/$folder/$cycleDir'.ps'
done
cd -

cd validation_s2
for file in `ls *.ps`
do
  # Folder name is the same as PS file excluding .ps
  # The following command trim the last 3 character: .ps
  folder=`echo "${file::-3}"`
  echo $file
  cp $file $mainDIR/archive/$folder/$cycleDir'.ps'
done
cd -
# ------------------------------------------------------------
#                       Free up space

# Directing tdirectory containig forecast cycles (working dir)
cd $mainDIR/$ID

# Find the directory created 6 days before the creation of the
# latest directory
#     i.e. If the system stops running, the current and recent
#     directorie won’t be deleted. Only those will be deleted 
#     that are 6 days older than the latest ones.
current=`cat currentCycle`

# Finding old directories
old_dir=`date +'%Y%m%d' -d "$currentCycle 6 days ago"`

# List all files in the working dir 
list=`find * -maxdepth 0 -type d | grep $old_dir`

# Deleting
rm -rf echo $list 

# Reporting
deleted=`find * -maxdepth 0 -type d | grep $old_dir`
logMessage "Old forcast directories deleted $deleted"
