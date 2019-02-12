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
HOSTNAME=$1
STORMDIR=$2
ADVISORY=$3
ENSTORM=$4
estuary=$5
PHASE=$6
EMAILNOTIFY=$7
SYSLOG=$8   
ADDRESS_LIST=$9
CONFIG=${10}
. $CONFIG
. ${mainDIR}/src/logging.sh
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
# --------------------------------------------------------------------------
#                            A C T I V A T I O N
# --------------------------------------------------------------------------
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
# --------------------------------------------------------------------------
#                       N E W    C Y C L E -- NAM
# --------------------------------------------------------------------------
"newcycle")
#
cat <<END > $STORMDIR/new_advisory.txt 2>> ${SYSLOG}
This is an automated message from ASGS-Multistage
running on ${HOSTNAME}.

The computer $HOSTNAME has detected a new NAM cycle
(cycle $ADVISORY) from the National Centers for Environmental
Prediction (NCEP). The forcing data have been downloaded; ADCIRC surge
calculations are about to begin for the $estuary domain. 

You will receive another email from the ASGS-Multistage on $HOSTNAME
as soon as the resulting storm surge guidance becomes available.

END
    logMessage "Sending 'new cycle detected' email to the following addresses: $COMMA_SEP_LIST."
    cat $STORMDIR/new_advisory.txt | mail -s "new cycle ($ADVISORY) detected by ASGS-Multistage on $HOSTNAME" "$COMMA_SEP_LIST" 2>> ${SYSLOG} 2>&1
;;
# --------------------------------------------------------------------------
#              N E W    A D V I S O R Y -- Tropical Cyclone
# --------------------------------------------------------------------------
"newAdv")
#
cat <<END > $STORMDIR/new_advisory.txt 2>> ${SYSLOG}
This is an automated message from ASGS-Multistage
running on ${HOSTNAME}.

The supercomputer $HOSTNAME has detected a new advisory (number $ADVISORY)
from the National Hurricane Center for $STORMNAME ${YEAR}.
ADCIRC surge calculations are about to begin for the $estuary domain.

You will receive another email from the ASGS-Multistage on $HOSTNAME
as soon as the resulting storm surge guidance becomes available.

END
    logMessage "Sending 'New advisory detected' email to the following addresses: $COMMA_SEP_LIST."
    cat $STORMDIR/new_advisory.txt | mail -s "New advisory (number $ADVISORY) detected by ASGS-Multistage on $HOSTNAME" "$COMMA_SEP_LIST" 2>> ${SYSLOG} 2>&1
;;
# --------------------------------------------------------------------------
#                          J O B   F A I L E D 
# --------------------------------------------------------------------------
"jobfailed")
#
cat <<END > ${STORMDIR}/job_failed_notify.txt 
This is an automated message from ASGS-Multistage
running on ${HOSTNAME}.

A job running on the computer $HOSTNAME has failed while running 
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
