set term postscript enhanced
set size 2.2,1
set output "CPRG_HS.ps"
set terminal postscript "TimesRoman" 20
set title "Sebastian Inlet (CPRG station 80.445W 27.867N) \n\n        Validation cycle: %oldcycle%                                                                                               Current cycle: %cycle%                                                         "
set grid
set xdata time
set format x "%m/%d-%HZ"
set xtics 43200
set mxtics 12
set key outside bottom horizontal center
set key font ",15"
set datafile missing "-99999"
set timefmt "%Y-%m-%d %H:%M:%S"
set yrange [:]
set autoscale xfix
set ylabel "Hs (m)"
count1(fname)=system(sprintf("awk 'NR>2 && $6!=-99999.0000 { print $0 }' %s | wc -l",fname))
k=count1("single_swan61")
#
# if this column consists of only missing values, write a message but
# don't plot anything; only pretend to plot something so that we get the
# right time range across the bottom; if there are real values, plot them
set style circle radius 2500
plot "single_swan61_old"  using  1:9:14  with filledcurves lc 9 title "GEFS ensemble spread", \
     ""                   using  1:9:19  with filledcurves lc 9 notitle, \
     ""                   using  1:14:19  with filledcurves lc 9 notitle, \
     ""                   using  1:24:29 lt rgb "#2F4F4F" with filledcurves title "SREF ensemble spread", \
     ""                   using  1:24:34 lt rgb "#2F4F4F" with filledcurves notitle, \
     ""                   using  1:29:34 lt rgb "#2F4F4F" with filledcurves notitle, \
     ""                   using  1:4  lt 1 lc 7 lw 3 title "Forced by NAM" with lines, \
     ""                   using  1:9  with lines lt 1 lc rgb "gray20" lw 3 title "Forced by GEFS mean", \
     ""                   using  1:14 with lines lt 2 lc rgb "gray20" lw 3 title "Forced by GEFS mean + std", \
     ""                   using  1:19 with lines lt 5 lc rgb "gray20" lw 3 title "Forced by GEFS mean - std", \
     ""                   using  1:24 with lines lt 1 lc rgb "midnight-blue" lw 3 title "Forced by SREF mean", \
     ""                   using  1:29 with lines lt 2 lc rgb "midnight-blue" lw 3 title "Forced by SREF mean + std", \
     ""                   using  1:34 with lines lt 5 lc rgb "midnight-blue" lw 3 title "Forced by SREF mean - std", \
     "obs-cprg-HS"    using  1:4 with linespoints lw 2 lc rgb "black" notitle, \
     ""               using  1:4 lc rgb "orange" title "Observed" with circles fill solid border lt 1, \
     "single_swan61"  using  1:4:9   with filledcurves lc 5 title "Ensemble spread", \
     "single_swan61"  using  1:4:14  with filledcurves lc 5 notitle, \
     "single_swan61"  using  1:4:19  with filledcurves lc 5 notitle, \
     "single_swan61"  using  1:4:24  with filledcurves lc 5 notitle, \
     "single_swan61"  using  1:4:29  with filledcurves lc 5 notitle, \
     "single_swan61"  using  1:4:34  with filledcurves lc 5 notitle, \
     "single_swan61"  using  1:9:14  with filledcurves lc 5 notitle, \
     "single_swan61"  using  1:9:19  with filledcurves lc 5 notitle, \
     "single_swan61"  using  1:9:24  with filledcurves lc 5 notitle, \
     "single_swan61"  using  1:9:29  with filledcurves lc 5 notitle, \
     "single_swan61"  using  1:9:34  with filledcurves lc 5 notitle, \
     "single_swan61"  using  1:14:19 with filledcurves lc 5 notitle, \
     "single_swan61"  using  1:14:24 with filledcurves lc 5 notitle, \
     "single_swan61"  using  1:14:29 with filledcurves lc 5 notitle, \
     "single_swan61"  using  1:14:34 with filledcurves lc 5 notitle, \
     "single_swan61"  using  1:19:24 with filledcurves lc 5 notitle, \
     "single_swan61"  using  1:19:29 with filledcurves lc 5 notitle, \
     "single_swan61"  using  1:19:39 with filledcurves lc 5 notitle, \
     "single_swan61"  using  1:24:29 with filledcurves lc 5 notitle, \
     "single_swan61"  using  1:24:34 with filledcurves lc 5 notitle, \
     "single_swan61"  using  1:29:34 with filledcurves lc 5 notitle, \
     "single_swan61"  using  1:4  lt 1 lc 7 lw 2 title "Forced by NAM"  with lines, \
     ""               using  1:9  lt 1 lc 1 lw 2 title "Forced by GEFS mean"  with lines, \
     ""               using  1:14 lt 1 lc 3 lw 2 title "Forced by GEFS mean + std"  with lines, \
     ""               using  1:19 lt 1 lc 4 lw 2 title "Forced by GEFS mean - std"  with lines, \
     ""               using  1:24 lt 4 lc 1 lw 4 title "Forced by SREF mean"  with lines, \
     ""               using  1:29 lt 4 lc 3 lw 4 title "Forced by SREF mean + std"  with lines, \
     ""               using  1:34 lt 4 lc 4 lw 4 title "Forced by SREF mean - std"  with lines, \
     "line-cprg-HS"   using  1:4  lt 2 lc 7 lw 5 notitle with lines, \
     "obs-cprg-HS"    using  1:4 with linespoints lw 2 lc rgb "black" notitle, \
     ""               using  1:4 lc rgb "orange" notitle with circles fill solid border lt 1, \
