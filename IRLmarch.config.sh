#!/bin/bash
#
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
#                            General setting   
#
ID=IRLMarch                   # simulation ID (the name of the coastal estuary)
estuary="IndianRiverLagoon"   # The name of the estuary
HINDCASTLENGTH=10        # total length of stage one simulation       
HOTSTARTFORMAT=binary    # Hotstart file format (netCDF not supported yet)
platform=coconut         # Name
#                 
NCPU=46                  # Number of CPUs to use (same for stage one and two)
outputWriter=0           # Number of output writers (not supported yet)
MET="gridded"                                 # Meteorology type: [gridded/NHC]
#
EXEDIR=/home/ptaeb/ADCIRC/v52release/work/    # dir containing ADCIRC executable files
SCRDIR=/home/ptaeb/multi.stage/               # dir containing multi-stage scripts
PERL5LIB=/home/ptaeb/multi.stage/PERL         # dir containing DataCale.pm perl module
#
s1_INPDIR=/home/ptaeb/multi.stage/input/domain/adjstd.ec95/  # dir containing stage 1 mesh, nodal attribute
s2_INPDIR=/home/ptaeb/multi.stage/input/domain/IRL/          # dir containing stage 2 mesh, nodal attribute, swan template 
met_INPDIR=/home/ptaeb/multi.stage/input/MET/march.WRF       # dir containing meteorological forcing
#
# Time interval of inputing wind and pressure input file (nws=12, 312)
windInterval=1800
#
# ----------------------------------------------------------------
#                 S T A G E   O N E     I N P U T S
#
CSDATE=2015022600                      # cold start time
S1_dt=20                               # time step size
s1_grd=adjstd.ec95.grd                 # grid name
s1_cntrl=ec95.fort.15_temp             # ctntrol file
s1_ndlattr=adjstd.ec95.ndl.attr.13     # nodall atribute input file   
#
# ----------------------------------------------------------------
#                 S T A G E   T W O     I N P U T S
#
S2_dt=1  
s2_grd=ecIRL.PD.v2.0.0.HRLA.grd
s2_cntrl=control.adcirc.15
s2_ndlattr=ecIRL.PD.v2.0.0.HRLA.13
s2_swan26=control.swan.26
ELEVSTATIONS=null
VELSTATIONS=null
METSTATIONS=null
# ----------------------------------------------------------------
#                  W A V E S (S2)
WAVES=on                   # waves "on" or "off"
SWANDT=1200
S2SPINUP=1                 # spin-up time for HRLA domain (in days)
hotswan="off"
fricType=JONswap           # SWAN BOTTOM FRICTION TYPE
#
# ------------------------------------------------------------------------
#                        M E T     F I L E      
basinP=wrf_30min_2015030500_2015030800_p_9kmll_patchd1.dat
basinUV=wrf_30min_2015030500_2015030800_uv_9kmll_patchd1.dat
regionalP=wrf_30min_2015030500_2015030800_p_halfkmll_patchd4.dat
regionalUV=wrf_30min_2015030500_2015030800_uv_halfkmll_patchd4.dat
#
NHCmet=fort.22_matthew_5th.9th 
EVENTDATE=2015030500              # Meteorology start time
#
# ---------------------------------------------------------------
#                B O U N D AR Y     C O N D I T I O N
#
# Boundary forcing type: elevation, or flux (flux not supported yet)
BCTYPE=elevation
# Boundary forcing frequency (time interval)
BCFREQ=900
# boundary nodes, executable, etc
BNDIR=/home/ptaeb/multi.stage/buildf19/
BNNAME=BN_irl.PD.adjstd.ec95      
#-------------------------------------------------------------------
#                       Output configuration 
#
FORT61="--fort61freq 900"      # water surface elevation station output 
FORT62="--fort62freq 900.0"    # water current velocity station output       
FORT63="--fort63freq 1800.0 --fort63netcdf --netcdf4"   # full domain water surface elevation output   
#FORT63="--fort63freq 1800.0 --fort63netcdf netcdf"
#FORT63="--fort63freq 1800.0" 
FORT64="--fort64freq 1800.0"      # full domain water current velocity output 
FORT7172="--fort7172freq 900.0"   # met station output
FORT7374="--fort7374freq 1800.0"  # full domain meteorological output
NETCDF4="--netcdf4"
OUTPUTOPTIONS="${FORT61} ${FORT62} ${FORT63} ${FORT64} ${FORT7172} ${FORT7374}"
#-------------------------------------------------------------------
#                       Notification configuration 
#-------------------------------------------------------------------
EMAILNOTIFY=yes                       # yes/no
notidy_script=notification
notify_list="ptaeb2014@my.fit.edu"
TYPE="email"                         # screen/email
#
