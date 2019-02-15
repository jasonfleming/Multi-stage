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
ID=NAM_GEFS                   # simulation ID (the name of the coastal estuary)
estuary="IndianRiverLagoon"   # The name of the estuary
HINDCASTLENGTH=10             # Total length of stage one simulation       
HOTSTARTFORMAT=binary         # Hotstart file format (netCDF not supported yet)
platform=coconut              #
#                 
NCPU=46                       # Number of CPUs to use (same for stage one and two)
outputWriter=0                # Number of output writers (not supported yet)
MET="background"              # Meteorology type: [background/TC]
#
EXEDIR=/home/ptaeb/ADCIRC/v52release/work/        # dir containing ADCIRC executable files
mainDIR=/home4/ptaeb/multi.stage/                 # dir containing multi-stage scripts
PERL5LIB=/home4/ptaeb/multi.stage/utility/PERL    # dir containing DataCale.pm perl module
#
s1_INPDIR=/home4/ptaeb/multi.stage/input/domain/ecPT/       # dir containing stage 1 mesh, nodal attribute
s2_INPDIR=/home4/ptaeb/multi.stage/input/domain/IRL/        # dir containing stage 2 mesh, nodal attribute, swan template 
met_INPDIR=/home4/ptaeb/multi.stage/MET/                    # dir containing meteorological forcing
#
# -------------------------------------------------------------------------
#                   M O D E (forecast/hindcast)
MODE="FORECAST"                        # FORECAST/HINDCAST

# We use NAM analysis for both coarse and fine mesh. No GEFS on nowcast as nowcast is performed to spin up the meteorology
#NAM_analysis_wind=/home/ptaeb/GEFS.multistage/version-2/uv/NAM_2018100812_2018100900.222
#NAM_analysis_press=/home/ptaeb/GEFS.multistage/version-2/uv/NAM_2018100812_2018100900.221

#HINDCAST_NWS12_wind_s1=/home/ptaeb/GEFS.multistage/version-2/uv/fort.222_mean_ec_large
#HINDCAST_NWS12_press_s1=/home/ptaeb/GEFS.multistage/version-2/uv/fort.221_mean_ec_large

#HINDCAST_NWS12_wind_s2=/home/ptaeb/GEFS.multistage/version-2/uv/fort.222_mean_IRL
#HINDCAST_NWS12_press_s2=/home/ptaeb/GEFS.multistage/version-2/uv/fort.221_mean_IRL

#nowCSDATE=2018100812   # Uncomment it for hindcast and developing purposes
#nowenddate=2018100900

#forecastCSDATE=2018100900
#forecastenddate=2018101212
# ----------------------------------------------------------------
#                 S T A G E   O N E     I N P U T S
#
CSDATE=2019010600                      # cold start time
S1_dt=20                               # time step size
s1_grd=ecPT.v4.smootherThan3.grd       # grid name
s1_cntrl=control.adcirc.15             # ctntrol file
s1_ndlattr=ecPT.v4.smootherThan3.13    # nodall atribute input file   
s1_swan26=control.swan.26
s1_ELEVSTATIONS=s1.stations.txt
s1_VELSTATIONS=s1.current.station.txt
s1_METSTATIONS=s1.stations.txt
s1_WAVESTATION=wave-coarseMesh
#
# ----------------------------------------------------------------
#                 S T A G E   T W O     I N P U T S
#
S2_dt=1  
s2_grd=ecIRL.HRLA.PD.v7.2.grd  
s2_cntrl=control.adcirc.15
s2_ndlattr=ecIRL.HRLA.PD.v7.2.13  
s2_swan26=control.swan.26
s2_ELEVSTATIONS=s2.stations.txt
s2_VELSTATIONS=null
s2_METSTATIONS=s2.stations.txt
# ----------------------------------------------------------------
#                  W A V E S (S2)
WAVES="on"                 # waves "on" or "off"
SWANDT=1800
S2SPINUP=0                 # spin-up time for HRLA domain (in days)
fricType=JONswap           # SWAN BOTTOM FRICTION TYPE
#
# -------------------------------------------------------------------
#                  Background Meteorology
#
# The NAM input configuration is ignored if BACKGROUNDMET=off.
BACKSITE=ftp.ncep.noaa.gov           # NAM forecast data from NCEP
BACKDIR=/pub/data/nccf/com/nam/prod  # contains the nam.yGyyymmdd files
FORECASTLENGTH=84                    # hours of NAM forecast to run (max 84)
PTFILE=ptFile.txt                    # the file that provides the lat/lons
                                     # for the OWI background met
FORECASTCYCLE="00,06,12,18"
#
#
# ALTNAMDIR="/corral/hurri:cane/asgs_output,/corral/hurricane/asgs_ec95d"
# ALTNAMDIR="/projects/ncfs/data/asgs5463","/projects/ncfs/data/asgs14174"
# ------------------------------------------------------------------
#                            TROPICAL CYCLONE
#
# The tropical cyclone input configuration is ignored if TROPICALCYCLONE=off.
START=coldstart        # "hotstart" or "coldstart". Equal to HOTORCOLD in asgs
STARTADVISORYNUM=11    # starting advisory number, set to zero if
                       # downloading forecast advisories via rss
STORMNAME=Alberto      # equal to INSTANCENAME in asgs
STORM=01 
YEAR=2018
TRIGGER=ftp                # either "ftp" or "rss"
RSSSITE=www.nhc.noaa.gov   # site information for retrieving advisories
FTPSITE=ftp.nhc.noaa.gov   # real anon ftp site for hindcast/forecast files
#FDIR=/atcf/afst          # Old forecast dir on nhc ftp site
FDIR=/atcf/fst             # New forecast dir on nhc ftp site
HDIR=/atcf/btk             # hindcast dir on nhc ftp site
RMAX=default
PERCENT=default
ENSEMBLESIZE=1          # number of storms in the ensemble
STORMLIST[0]=1          # NHC consensus forecast
case  $si  in
0)
  ENSTORM=forecast   
  ;;
esac
# ------------------------------------------------------------------
#                B O U N D AR Y     C O N D I T I O N
#
# Boundary forcing type: elevation, or flux (flux not supported yet)
BCTYPE=elevation
# Boundary forcing frequency (time interval)
BCFREQ=20 
# boundary nodes, executable, etc
BNDIR=/home4/ptaeb/multi.stage/utility/buildf19/
BNNAME=BN_IRL_adjstd_LatLon       
#-------------------------------------------------------------------
#                       Output configuration 
#
FORT61="--fort61freq 900"     # water surface elevation station output 
FORT62="--fort62freq 1800"    # water current velocity station output       
#FORT63="--fort63freq 1800.0 --fort63netcdf --netcdf4"   # full domain water surface elevation output   
#FORT63="--fort63freq 1800.0 --fort63netcdf netcdf"
FORT63="--fort63freq 1800.0" 
FORT64="--fort64freq 1800.0"      # full domain water current velocity output 
FORT7172="--fort7172freq 1800.0"   # met station output
FORT7374="--fort7374freq 1800.0"  # full domain meteorological output
NETCDF4="--netcdf4"
OUTPUTOPTIONS="${FORT61} ${FORT62} ${FORT63} ${FORT64} ${FORT7172} ${FORT7374}"
#-------------------------------------------------------------------
#                       Notification configuration 
#-------------------------------------------------------------------
EMAILNOTIFY=yes # set to yes to have host platform email notifications
NOTIFY_SCRIPT=gen_notify.sh
ACTIVATE_LIST="ptaeb2014@my.fit.edu"
NEW_ADVISORY_LIST="ptaeb2014@my.fit.edu"
POST_INIT_LIST="ptaeb2014@my.fit.edu"
POST_LIST="ptaeb2014@my.fit.edu"
notify_list="ptaeb2014@my.fit.edu"
#
#-------------------------------------------------------------------
#                   Post Processing configuration
#-------------------------------------------------------------------
INITPOST=FIT_init_post.sh
POSTPROCESS=visualize_post.sh
TARGET=coconut
github=/home4/ptaeb/GitHub/
