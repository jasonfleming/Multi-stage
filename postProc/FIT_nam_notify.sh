#!/bin/bash
#
# Copyright(C) 2008--2012 Jason Fleming
#
# This file is part of the ADCIRC Surge Guidance System (ASGS).
#
# The ASGS is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# ASGS is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with the ASGS.  If not, see <http://www.gnu.org/licenses/>.
#
#
logMessage()
{ DATETIME=`date +'%Y-%h-%d-T%H:%M:%S'`
  MSG="[${DATETIME}] INFO: $@"
  echo ${MSG} >> ${SYSLOG}
}

HOSTNAME=$1
STORM=$2
YEAR=$3
STORMDIR=$4
ADVISORY=$5
ENSTORM=$6
GRIDFILE=$7
PHASE=$8
EMAILNOTIFY=$9
SYSLOG=${10}
ADDRESS_LIST=${11}
OUTPUTPREFIX=${STORM}_${YEAR}_${ENSTORM}_${ADVISORY}
#
# simply return if we are not supposed to send out emails
if [[ $EMAILNOTIFY != yes && $EMAILNOTIFY != YES ]]; then
   exit
fi
#
# simply return if there are no email addresses to send email to
if [[ $ADDRESS_LIST = null ]]; then
   exit
fi
#
COMMA_SEP_LIST=${ADDRESS_LIST// /,}
case $PHASE in
#
#               A C T I V A T I O N
#
"activation")
#
cat <<END > $STORMDIR/activate.txt 2>> ${SYSLOG}
This is an automated message from the ADCIRC Surge Guidance System (ASGS)
running on ${HOSTNAME}.

This message is to let you know that the ASGS has been ACTIVATED and is using
the North American Mesoscale (NAM) model for meteorological forcing. Results
will be produced using the $GRIDFILE grid. 

You will continue to receive email from the ASGS on $HOSTNAME
as the results become available.

END
    logMessage "Sending activation email to the following addresses: $COMMA_SEP_LIST."
    cat $STORMDIR/activate.txt | mail -s "ASGS Activated on $HOSTNAME" "$COMMA_SEP_LIST" 2>> ${SYSLOG} 2>&1
;;
#
#              N E W  C Y C L E 
#
"newcycle")
#
cat <<END > $STORMDIR/new_advisory.txt 2>> ${SYSLOG}
This is an automated message from the ADCIRC Surge Guidance System (ASGS)
running on ${HOSTNAME}.

The supercomputer $HOSTNAME has detected a new NAM cycle
(number $ADVISORY) from the National Centers for Environmental
Prediction (NCEP). The forcing data have been downloaded; ADCIRC surge
calculations are about to begin, using the $GRIDFILE grid. 

You will receive another email from the ASGS on $HOSTNAME
as soon as the resulting storm surge guidance becomes available.

END
    logMessage "Sending 'new cycle detected' email to the following addresses: $COMMA_SEP_LIST."
     cat $STORMDIR/new_advisory.txt | mail -s "new cycle detected by ASGS on $HOSTNAME" "$COMMA_SEP_LIST" 2>> ${SYSLOG} 2>&1
;;
# ------------------------------------------------------------------------
#                               R E S U L T S 
# ------------------------------------------------------------------------
"results")
cd $ADVISDIR/$ENSTORM/
ENDTIME=`grep "EndTime" run.properties | cut -d ":" -f2`
cd -
#
cat <<END > ${STORMDIR}/post_notify.txt 
This is an automated message from the ADCIRC Surge Guidance System (ASGS)
running on ${HOSTNAME} in Coastal Engineering Lab
at Florida Institute of Technology, 

The supercomputer $HOSTNAME has produced ADCIRC results for 
NAM cycle $ADVISORY on the $GRIDFILE grid. 

Figuers attached are 2D contours of Max surface elevation of:
- Full domain (Western North Atlantic, Gulf of Mexico, and Caribbean Sea),
- East Coast of Central Florida including IRL grid,
- And significant wave height for East Coast of Central Florida including IRL grid, 
And surface elevation and wind speed time series at:
- NOAA   station in Trident Pier,
- NOAA   station in Virginia Key
- CSTAR  station in Lansing Island,
- CSTAR  station in Sebastion Fishing Pier In Riverview Park,
- SJRWDM station in 192 Melbourne Causeway,
From $ADVISORY through$ENDTIME 

These results can be found at the following directory:

----------- /home3/ptaeb/asgs/output/ on $HOSTNAME ---------------

The ASGS on $HOSTNAME is now waiting for next NAM cycle. 
END
#
echo "INFO: FIT_TC_notify.sh: Sending 'results notification' email to the following addresses: $COMMA_SEP_LIST."
cat ${STORMDIR}/post_notify.txt | mail -s "ASGS results available for $STORMNAME advisory $ADVISORY from $HOSTNAME"  -a /home3/ptaeb/asgs/output/$OUTPUTPREFIX/plot10001.jpg -a /home3/ptaeb/asgs/output/$OUTPUTPREFIX/plot20001.jpg -a /home3/ptaeb/asgs/output/$OUTPUTPREFIX/plot30001.jpg -a /home3/ptaeb/asgs/output/$OUTPUTPREFIX/plots/EW_Trident_Pier.png -a /home3/ptaeb/asgs/output/$OUTPUTPREFIX/plots/EW_Virginia_Key.png -a /home3/ptaeb/asgs/output/$OUTPUTPREFIX/plots/EW_Lansing_Island.png -a /home3/ptaeb/asgs/output/$OUTPUTPREFIX/plots/EW_Sebastion_fishing_pier.png -a /home3/ptaeb/asgs/output/$OUTPUTPREFIX/plots/EW_Melbourne_Cause_way.png  "$COMMA_SEP_LIST" 2>> ${SYSLOG} 2>&1
;;
# --------------------------------------------------------------------------
#                          J O B   F A I L E D 
# --------------------------------------------------------------------------
"jobfailed")
#
cat <<END > ${STORMDIR}/job_failed_notify.txt 
This is an automated message from the ADCIRC Surge Guidance System (ASGS)
running on ${HOSTNAME}.

A job running on the supercomputer $HOSTNAME has failed while running 
NAM cycle $ADVISORY on the $GRIDFILE grid.

END
#
logMessage "Sending 'job_failed' email to the following addresses: $COMMA_SEP_LIST."
cat ${STORMDIR}/job_failed_notify.txt | mail -s "ASGS job failed for cycle $ADVISORY on $HOSTNAME" "$COMMA_SEP_LIST" 2>> ${SYSLOG} 2>&1
;;
*)
logMessage "ERROR: corps_nam_notify.sh: The notification type was specified as '$PHASE', which is not recognized. Email was not sent."
;;
esac
