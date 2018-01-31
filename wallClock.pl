#!/usr/bin/env perl
#
# This scripts reads the start run time of the state one simulation
# and the end run time of the stage two simulation to calculate the
# total run time. 
# This Perl script reads a template notification text file located 
# (usually) in the postProc folder, and write wallclock time in it.
# Notification will be send as screen output, or an email specified
# by user in the config file. 
#
# usage:
# %perl wallClock.pl --st $STARTRUN --et $ENDRUN
# --------------------------------------------------------------------------
# Copyright(C) 2018 Florida Institute of Technology
# Copyright(C) 2018 Peyman Taeb & Robert J Weaver
#
# This program is prepared as a part of the Multi-stage tool.
# The Multi-stage tool is an open-source software providing the copyright
# holders the rights to run, study, change, and distribute the software under
# the terms and conditions of the third version of the GNU General Public
# License (GPLv3) as published in 2007.
# 
# Although careful considerations are given to the development of the
# Multi-stage tool with the aim of usefulness and helpfulness, we do not
# make any warranty express or implied, do not assume any responsibility for
# the accuracy, completeness, or usefulness of any components and outcomes.
# 
# The terms and conditions of the GPL are available to anybody receiving a
# copy of the Multi-stage tool. It can be also found in
# <http://www.gnu.org/licenses/gpl.html>.
# --------------------------------------------------------------------------
#
$^W++;
use strict;
use Getopt::Long;
use Date::Pcalc;
use Cwd;
#
my $startRun;
my $endRun;
my $notify_script;
my $RUNDIR;
#
our ($sy, $sm, $sd, $sh, $smin, $ss); # Start run time
our ($ey, $em, $ed, $eh, $emin, $es); # End run time 
# 
GetOptions("st=s" => \$startRun,
           "et=s" => \$endRun,
           "not=s" => \$notify_script, 
           "dir=s" => \$RUNDIR
           );
#
# parse out the pieces of the stage one start time
$startRun=~ m/(\d\d\d\d)(\d\d)(\d\d)(\d\d)(\d\d)(\d\d)/;
$sy = $1;
$sm = $2;
$sd = $3;
$sh = $4;
$smin = $5;
$ss = $6;
#
# parse out the pieces of the stage two end time
$endRun=~ m/(\d\d\d\d)(\d\d)(\d\d)(\d\d)(\d\d)(\d\d)/;
$ey = $1;
$em = $2;
$ed = $3;
$eh = $4;
$emin = $5;
$es = $6;
# 
# get difference
   (my $Ddays, my $Dhrs, my $Dmin, my $Dsec)
        = Date::Pcalc::Delta_DHMS(
           $sy,$sm,$sd,$sh,$smin,$ss,
           $ey,$em,$ed,$eh,$emin,$es);
#
unless (open(FILE,"<$notify_script")) {
   stderrMessage("ERROR","Failed to open the notifying file $notify_script for reading: $!.");
   die;
}
unless (open(OUTPUT,">$RUNDIR/notifying.sh")) {
  stderrMessage("ERROR","Failed to open the notifying file for writing: $!.");
   die;
}
while(<FILE>) {
     s/%DAYS%/$Ddays/;
     s/%HOURS%/$Dhrs/;
     s/%MIN%/$Dmin/;
     s/%SEC%/$Dsec/;
     unless (/NO LINE HERE/) {
     print OUTPUT $_;
     }
}
close(FILE);
close(OUTPUT);
#--------------------------------------------------------------------------
#   S U B   S T D E R R  M E S S A G E
#
# Writes a log message to standard error.
#--------------------------------------------------------------------------
sub stderrMessage () {
   my $level = shift;
   my $message = shift;
   my @months = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
   (my $second, my $minute, my $hour, my $dayOfMonth, my $month, my $yearOffset, my $dayOfWeek, my $dayOfYear, my $daylightSavings) = localtime();
   my $year = 1900 + $yearOffset;
   my $hms = sprintf("%02d:%02d:%02d",$hour, $minute, $second);
   my $theTime = "[$year-$months[$month]-$dayOfMonth-T$hms]";
   printf STDERR "$theTime $level: wallClock.pl: $message\n";
   if ($level eq "ERROR") {
      sleep 60
   }
}
