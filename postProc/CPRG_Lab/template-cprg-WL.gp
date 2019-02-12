set term postscript enhanced
set size 2.2,1 
set output "CPRG_WL.ps"
set terminal postscript "TimesRoman" 20
set title "BC validation at Sebastian Inlet (CPRG station 80.445W 27.861N) \n\n        Validation cycle: %oldcycle%                                                                                               Current cycle: %cycle%                                                      "
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
#count1(fname)=system(sprintf("awk 'NR>2 && $6!=-99999.0000 { print $0 }' %s | wc -l",fname))
#k=count1("obs-cprg-trim")
#
# if this column consists of only missing values, write a message but
# don't plot anything; only pretend to plot something so that we get the
# right time range across the bottom; if there are real values, plot them
set style circle radius 1500
plot "single_fort61_old"  using  1:15:25 with filledcurves lc 9 title "GEFS ensemble spread", \
     ""                   using  1:15:35 with filledcurves lc 9 notitle, \
     ""                   using  1:25:35 with filledcurves lc 9 notitle, \
     ""                   using  1:45:55 lt rgb "#2F4F4F" with filledcurves title "SREF ensemble spread", \
     ""                   using  1:45:65 lt rgb "#2F4F4F" with filledcurves notitle, \
     ""                   using  1:55:65 lt rgb "#2F4F4F" with filledcurves notitle, \
     ""                   using  1:5 lt 1 lc 7 lw 3 title "Forced by NAM" with lines, \
     ""                   using  1:15 with lines lt 1 lc rgb "gray20" lw 3 title "Forced by GEFS mean", \
     ""                   using  1:25 with lines lt 2 lc rgb "gray20" lw 3 title "Forced by GEFS mean + std", \
     ""                   using  1:35 with lines lt 5 lc rgb "gray20" lw 3 title "Forced by GEFS mean - std", \
     ""                   using  1:45 with lines lt 1 lc rgb "midnight-blue" lw 3 title "Forced by SREF mean", \
     ""                   using  1:55 with lines lt 2 lc rgb "midnight-blue" lw 3 title "Forced by SREF mean + std", \
     ""                   using  1:65 with lines lt 5 lc rgb "midnight-blue" lw 3 title "Forced by SREF mean - std", \
     "obs-cprg-trim"      using  1:5 lc rgb "orange" title "Observed" with circles fill solid border lt 1, \
     "single_fort61"  using  1:5:15  with filledcurves lc 5 title "Ensemble spread", \
     "single_fort61"  using  1:5:25  with filledcurves lc 5 notitle, \
     "single_fort61"  using  1:5:35  with filledcurves lc 5 notitle, \
     "single_fort61"  using  1:5:45  with filledcurves lc 5 notitle, \
     "single_fort61"  using  1:5:55  with filledcurves lc 5 notitle, \
     "single_fort61"  using  1:5:65  with filledcurves lc 5 notitle, \
     "single_fort61"  using  1:15:25 with filledcurves lc 5 notitle, \
     "single_fort61"  using  1:15:35 with filledcurves lc 5 notitle, \
     "single_fort61"  using  1:15:45 with filledcurves lc 5 notitle, \
     "single_fort61"  using  1:15:55 with filledcurves lc 5 notitle, \
     "single_fort61"  using  1:15:65 with filledcurves lc 5 notitle, \
     "single_fort61"  using  1:25:35 with filledcurves lc 5 notitle, \
     "single_fort61"  using  1:25:45 with filledcurves lc 5 notitle, \
     "single_fort61"  using  1:25:55 with filledcurves lc 5 notitle, \
     "single_fort61"  using  1:25:65 with filledcurves lc 5 notitle, \
     "single_fort61"  using  1:35:45 with filledcurves lc 5 notitle, \
     "single_fort61"  using  1:35:55 with filledcurves lc 5 notitle, \
     "single_fort61"  using  1:35:65 with filledcurves lc 5 notitle, \
     "single_fort61"  using  1:45:55 with filledcurves lc 5 notitle, \
     "single_fort61"  using  1:45:65 with filledcurves lc 5 notitle, \
     "single_fort61"  using  1:55:65 with filledcurves lc 5 notitle, \
     "single_fort61"  using  1:5  lt 1 lc 7 lw 2 title "Forced by NAM"  with lines, \
     ""               using  1:15 lt 1 lc 1 lw 2 title "Forced by GEFS mean"  with lines, \
     ""               using  1:25 lt 1 lc 3 lw 2 title "Forced by GEFS mean + std"  with lines, \
     ""               using  1:35 lt 1 lc 4 lw 2 title "Forced by GEFS mean - std"  with lines, \
     ""               using  1:45 lt 4 lc 1 lw 4 title "Forced by SREF mean"  with lines, \
     ""               using  1:55 lt 4 lc 3 lw 4 title "Forced by SREF mean + std"  with lines, \
     ""               using  1:65 lt 4 lc 4 lw 4 title "Forced by SREF mean - std"  with lines, \
     "line-cprg"      using  1:4  lt 2 lc 7 lw 5 notitle "" with lines, \
     "obs-cprg-trim"  using  1:5 lc rgb "orange" notitle with circles fill solid border lt 1, \
