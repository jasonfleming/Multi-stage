set term postscript enhanced
set output "Trident_dir.ps"
set size 2.2,1
set terminal postscript "TimesRoman" 20
#set title "Trident Pier (NOAA station 80.594W 28.417N) \n\n        Validation cycle: %oldcycle%                                                                                               Current cycle: %cycle%                                                      "
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
set ylabel "Wind Direction (Deg NT)"
#count1(fname)=system(sprintf("awk 'NR>2 && $6!=-99999.0000 { print $0 }' %s | wc -l",fname))
#k=count1("obs-cprg-trim")
#
# if this column consists of only missing values, write a message but
# don't plot anything; only pretend to plot something so that we get the
# right time range across the bottom; if there are real values, plot them
set style circle radius 1500
plot "single_fort72_dir_old"  using  1:10:15   with filledcurves lc 9 title "GEFS ensemble spread", \
     ""                   using  1:10:20  with filledcurves lc 9 notitle, \
     ""                   using  1:15:20  with filledcurves lc 9 notitle, \
     ""                   using  1:25:30 lt rgb "#2F4F4F" with filledcurves title "SREF ensemble spread", \
     ""                   using  1:25:35 lt rgb "#2F4F4F" with filledcurves notitle, \
     ""                   using  1:30:35 lt rgb "#2F4F4F" with filledcurves notitle, \
     ""                   using  1:5    with lines lt 1 lc 7 lw 3 title "Forced by NAM", \
     ""                   using  1:10   with lines lt 1 lc rgb "gray20" lw 3 title "Forced by GEFS mean", \
     ""                   using  1:15   with lines lt 2 lc rgb "gray20" lw 3 title "Forced by GEFS mean + std", \
     ""                   using  1:20   with lines lt 5 lc rgb "gray20" lw 3 title "Forced by GEFS mean - std", \
     ""                   using  1:25   with lines lt 1 lc rgb "midnight-blue" lw 3 title "Forced by SREF mean", \
     ""                   using  1:30   with lines lt 2 lc rgb "midnight-blue" lw 3 title "Forced by SREF mean + std", \
     ""                   using  1:35   with lines lt 5 lc rgb "midnight-blue" lw 3 title "Forced by SREF mean - std", \
     "wind-8721604-trimmed"   every  4::4    using  1:4 lc rgb "orange" title "Observed" with circles fill solid border lt 1, \
     "single_fort72_dir"      using  1:5:10  with   filledcurves lc 5 title "Ensemble spread", \
     ""                       using  1:5:15  with   filledcurves lc 5 notitle, \
     ""               using  1:5:20   with filledcurves lc 5 notitle, \
     ""               using  1:5:25   with filledcurves lc 5 notitle, \
     ""               using  1:5:30   with filledcurves lc 5 notitle, \
     ""               using  1:5:35   with filledcurves lc 5 notitle, \
     ""               using  1:10:15  with filledcurves lc 5 notitle, \
     ""               using  1:10:20  with filledcurves lc 5 notitle, \
     ""               using  1:10:25  with filledcurves lc 5 notitle, \
     ""               using  1:10:30  with filledcurves lc 5 notitle, \
     ""               using  1:10:35  with filledcurves lc 5 notitle, \
     ""               using  1:15:20  with filledcurves lc 5 notitle, \
     ""               using  1:15:25  with filledcurves lc 5 notitle, \
     ""               using  1:15:30  with filledcurves lc 5 notitle, \
     ""               using  1:15:35  with filledcurves lc 5 notitle, \
     ""               using  1:20:25  with filledcurves lc 5 notitle, \
     ""               using  1:20:30  with filledcurves lc 5 notitle, \
     ""               using  1:20:35  with filledcurves lc 5 notitle, \
     ""               using  1:25:30  with filledcurves lc 5 notitle, \
     ""               using  1:25:35  with filledcurves lc 5 notitle, \
     ""               using  1:30:35  with filledcurves lc 5 notitle, \
     ""               using  1:5  lt 1 lc 7 lw 2 title "Forced by NAM"  with lines, \
     ""               using  1:10 lt 1 lc 1 lw 2 title "Forced by GEFS mean"  with lines, \
     ""               using  1:15 lt 1 lc 3 lw 2 title "Forced by GEFS mean + std"  with lines, \
     ""               using  1:20 lt 1 lc 4 lw 2 title "Forced by GEFS mean - std"  with lines, \
     ""               using  1:25 lt 4 lc 1 lw 4 title "Forced by SREF mean"  with lines, \
     ""               using  1:30 lt 4 lc 3 lw 4 title "Forced by SREF mean + std"  with lines, \
     ""               using  1:35 lt 4 lc 4 lw 4 title "Forced by SREF mean - std"  with lines, \
     "line-TP-dir"    using  1:4 lt 2 lc 7 lw 5 notitle "" with lines, \
     "wind-8721604-trimmed"   using  1:4 every 4::4 lc rgb "orange" notitle with circles fill solid border lt 1, \
