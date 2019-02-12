set term postscript enhanced
set size 2.2,1 
set output "Wabasso_WL.ps"
set terminal postscript "TimesRoman" 20
set title "Wabasso (USGS station -80.427W 27.754N) \n\n        Validation cycle: %oldcycle%                                                                                               Current cycle: %cycle%                                                         "
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
plot "single_fort61_old"  using  1:12:19 with filledcurves lc 9 title "GEFS ensemble spread", \
     ""                   using  1:12:26 with filledcurves lc 9 notitle, \
     ""                   using  1:19:26 with filledcurves lc 9 notitle, \
     ""                   using  1:33:40 lt rgb "#2F4F4F" with filledcurves title "SREF ensemble spread", \
     ""                   using  1:33:47 lt rgb "#2F4F4F" with filledcurves notitle, \
     ""                   using  1:40:47 lt rgb "#2F4F4F" with filledcurves notitle, \
     ""                   using  1:5 lt 1 lc 7 lw 2 title "Forced by NAM" with lines, \
     ""                   using  1:12 with lines lt 1 lc rgb "gray20" lw 3 title "Forced by GEFS mean", \
     ""                   using  1:19 with lines lt 2 lc rgb "gray20" lw 3 title "Forced by GEFS mean + std", \
     ""                   using  1:26 with lines lt 5 lc rgb "gray20" lw 3 title "Forced by GEFS mean - std", \
     ""                   using  1:33 with lines lt 1 lc rgb "midnight-blue" lw 3 title "Forced by SREF mean", \
     ""                   using  1:40 with lines lt 2 lc rgb "midnight-blue" lw 3 title "Forced by SREF mean + std", \
     ""                   using  1:47 with lines lt 5 lc rgb "midnight-blue" lw 3 title "Forced by SREF mean - std", \
     "WL-wabasso-USGS"    using  1:4  lc rgb "orange" title "Observed" with circles fill solid border lt 1, \
     "single_fort61"  using  1:5:12  with filledcurves lc 5 title "Ensemble spread", \
     "single_fort61"  using  1:5:19  with filledcurves lc 5 notitle, \
     "single_fort61"  using  1:5:26  with filledcurves lc 5 notitle, \
     "single_fort61"  using  1:5:33  with filledcurves lc 5 notitle, \
     "single_fort61"  using  1:5:40  with filledcurves lc 5 notitle, \
     "single_fort61"  using  1:5:47  with filledcurves lc 5 notitle, \
     "single_fort61"  using  1:12:19 with filledcurves lc 5 notitle, \
     "single_fort61"  using  1:12:26 with filledcurves lc 5 notitle, \
     "single_fort61"  using  1:12:33 with filledcurves lc 5 notitle, \
     "single_fort61"  using  1:12:40 with filledcurves lc 5 notitle, \
     "single_fort61"  using  1:12:47 with filledcurves lc 5 notitle, \
     "single_fort61"  using  1:19:26 with filledcurves lc 5 notitle, \
     "single_fort61"  using  1:19:33 with filledcurves lc 5 notitle, \
     "single_fort61"  using  1:19:40 with filledcurves lc 5 notitle, \
     "single_fort61"  using  1:19:47 with filledcurves lc 5 notitle, \
     "single_fort61"  using  1:26:33 with filledcurves lc 5 notitle, \
     "single_fort61"  using  1:26:40 with filledcurves lc 5 notitle, \
     "single_fort61"  using  1:26:47 with filledcurves lc 5 notitle, \
     "single_fort61"  using  1:33:40 with filledcurves lc 5 notitle, \
     "single_fort61"  using  1:33:47 with filledcurves lc 5 notitle, \
     "single_fort61"  using  1:40:47 with filledcurves lc 5 notitle, \
     "single_fort61"  using  1:5  lt 1 lc 7 lw 2 title "Forced by NAM"  with lines, \
     ""               using  1:12 lt 1 lc 1 lw 2 title "Forced by GEFS mean"  with lines, \
     ""               using  1:19 lt 1 lc 3 lw 2 title "Forced by GEFS mean + std"  with lines, \
     ""               using  1:26 lt 1 lc 4 lw 2 title "Forced by GEFS mean - std"  with lines, \
     ""               using  1:33 lt 4 lc 1 lw 4 title "Forced by SREF mean"  with lines, \
     ""               using  1:40 lt 4 lc 3 lw 4 title "Forced by SREF mean + std"  with lines, \
     ""               using  1:47 lt 4 lc 4 lw 4 title "Forced by SREF mean - std"  with lines, \
     "line-wa" using 1:4 lt 2 lc 7 lw 5 notitle with lines, \
     "WL-wabasso-USGS" using 1:4 lc rgb "orange" notitle with circles fill solid border lt 1, \
