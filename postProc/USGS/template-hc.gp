set term postscript enhanced
set size 2.2,1 
set output "Haulover_WL.ps"
set terminal postscript "TimesRoman" 20
set title "Haulover Canal (USGS station 80.754W 28.736N) \n\n        Validation cycle: %oldcycle%                                                                                               Current cycle: %cycle%                                                         "
set grid
set xdata time
set format x "%m/%d-%H:%M"
set xtics 43200
set mxtics 12
set key outside bottom horizontal center
set key font ",15"
set datafile missing "-99999"
set timefmt "%Y-%m-%d %H:%M:%S"
set yrange [:]
set autoscale xfix
set ylabel "Surface Elevation (m) NAVD88"
count1(fname)=system(sprintf("awk 'NR>2 && $6!=-99999 { print $0 }' %s | wc -l",fname))
k=count1("single_fort61")
#
# if this column consists of only missing values, write a message but
# don't plot anything; only pretend to plot something so that we get the
# right time range across the bottom; if there are real values, plot them
set style circle radius 1500
plot "single_fort61_old"  using  1:11:18 with filledcurves lc 9 title "GEFS ensemble spread", \
     ""                   using  1:11:25 with filledcurves lc 9 notitle, \
     ""                   using  1:18:25 with filledcurves lc 9 notitle, \
     ""                   using  1:32:39 lt rgb "#2F4F4F" with filledcurves title "SREF ensemble spread", \
     ""                   using  1:32:46 lt rgb "#2F4F4F" with filledcurves notitle, \
     ""                   using  1:39:46 lt rgb "#2F4F4F" with filledcurves notitle, \
     ""                   using  1:4 lt 1 lc 7 lw 3 title "Forced by NAM" with lines, \
     ""                   using  1:11 with lines lt 1 lc rgb "gray20" lw 3 title "Forced by GEFS mean", \
     ""                   using  1:18 with lines lt 2 lc rgb "gray20" lw 3 title "Forced by GEFS mean + std", \
     ""                   using  1:25 with lines lt 5 lc rgb "gray20" lw 3 title "Forced by GEFS mean - std", \
     ""                   using  1:32 with lines lt 1 lc rgb "midnight-blue" lw 3 title "Forced by SREF mean", \
     ""                   using  1:39 with lines lt 2 lc rgb "midnight-blue" lw 3 title "Forced by SREF mean + std", \
     ""                   using  1:46 with lines lt 5 lc rgb "midnight-blue" lw 3 title "Forced by SREF mean - std", \
     "WL-haulovercanal-USGS" using 1:4 lc rgb "orange" title "Observed" with circles fill solid border lt 1, \
     "single_fort61"  using  1:4:11  with filledcurves lc 5 title "Ensemble spread", \
     "single_fort61"  using  1:4:18  with filledcurves lc 5 notitle, \
     "single_fort61"  using  1:4:25  with filledcurves lc 5 notitle, \
     "single_fort61"  using  1:4:32  with filledcurves lc 5 notitle, \
     "single_fort61"  using  1:4:39  with filledcurves lc 5 notitle, \
     "single_fort61"  using  1:4:46  with filledcurves lc 5 notitle, \
     "single_fort61"  using  1:11:18 with filledcurves lc 5 notitle, \
     "single_fort61"  using  1:11:25 with filledcurves lc 5 notitle, \
     "single_fort61"  using  1:11:32 with filledcurves lc 5 notitle, \
     "single_fort61"  using  1:11:39 with filledcurves lc 5 notitle, \
     "single_fort61"  using  1:11:46 with filledcurves lc 5 notitle, \
     "single_fort61"  using  1:18:25 with filledcurves lc 5 notitle, \
     "single_fort61"  using  1:18:32 with filledcurves lc 5 notitle, \
     "single_fort61"  using  1:18:39 with filledcurves lc 5 notitle, \
     "single_fort61"  using  1:18:46 with filledcurves lc 5 notitle, \
     "single_fort61"  using  1:25:32 with filledcurves lc 5 notitle, \
     "single_fort61"  using  1:25:39 with filledcurves lc 5 notitle, \
     "single_fort61"  using  1:25:46 with filledcurves lc 5 notitle, \
     "single_fort61"  using  1:32:39 with filledcurves lc 5 notitle, \
     "single_fort61"  using  1:32:46 with filledcurves lc 5 notitle, \
     "single_fort61"  using  1:39:46 with filledcurves lc 5 notitle, \
     "single_fort61"  using  1:4  lt 1 lc 7 lw 2 title "Forced by NAM"  with lines, \
     ""               using  1:11 lt 1 lc 1 lw 2 title "Forced by GEFS mean"  with lines, \
     ""               using  1:18 lt 1 lc 3 lw 2 title "Forced by GEFS mean + std"  with lines, \
     ""               using  1:25 lt 1 lc 4 lw 2 title "Forced by GEFS mean - std"  with lines, \
     ""               using  1:32 lt 4 lc 1 lw 4 title "Forced by SREF mean"  with lines, \
     ""               using  1:39 lt 4 lc 3 lw 4 title "Forced by SREF mean + std"  with lines, \
     ""               using  1:46 lt 4 lc 4 lw 4 title "Forced by SREF mean - std"  with lines, \
     "line-hc" using 1:4 lt 2 lc 7 lw 5 notitle with lines, \
     "WL-haulovercanal-USGS" using 1:4 lc rgb "orange" notitle with circles fill solid border lt 1, \
