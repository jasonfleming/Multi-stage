set term postscript enhanced
set size 2.2,1 
set output "CPRG_Cur.ps"
set terminal postscript "TimesRoman" 20
set title "Sebastian Inlet (CPRG station 80.445W 27.861N) \n\n        Validation cycle: %oldcycle%                                                                                               Current cycle: %cycle%                                                      "
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
set ylabel "Current velocity speed (m/s)"
#count1(fname)=system(sprintf("awk 'NR>2 && $6!=-99999.0000 { print $0 }' %s | wc -l",fname))
#k=count1("obs-cprg-trim")
#
# if this column consists of only missing values, write a message but
# don't plot anything; only pretend to plot something so that we get the
# right time range across the bottom; if there are real values, plot them
set style circle radius 1500
plot "single_fort62_old"  using  1:(sqrt($9*$9+$10*$10)):(sqrt($14*$14+$15*$15))   with filledcurves lc 9 title "GEFS ensemble spread", \
     ""                   using  1:(sqrt($9*$9+$10*$10)):(sqrt($19*$19+$20*$20))   with filledcurves lc 9 notitle, \
     ""                   using  1:(sqrt($14*$14+$15*$15)):(sqrt($19*$19+$20*$20)) with filledcurves lc 9 notitle, \
     ""                   using  1:(sqrt($24*$24+$25*$25)):(sqrt($29*$29+$30*$30)) lt rgb "#2F4F4F" with filledcurves title "SREF ensemble spread", \
     ""                   using  1:(sqrt($24*$24+$25*$25)):(sqrt($34*$34+$35*$35)) lt rgb "#2F4F4F" with filledcurves notitle, \
     ""                   using  1:(sqrt($29*$29+$30*$30)):(sqrt($34*$34+$35*$35)) lt rgb "#2F4F4F" with filledcurves notitle, \
     ""                   using  1:(sqrt($4*$4+$5*$5))     with lines lt 1 lc 7 lw 3 title "Forced by NAM", \
     ""                   using  1:(sqrt($9*$9+$10*$10))   with lines lt 1 lc rgb "gray20" lw 3 title "Forced by GEFS mean", \
     ""                   using  1:(sqrt($14*$14+$15*$15)) with lines lt 2 lc rgb "gray20" lw 3 title "Forced by GEFS mean + std", \
     ""                   using  1:(sqrt($19*$19+$20*$20)) with lines lt 5 lc rgb "gray20" lw 3 title "Forced by GEFS mean - std", \
     ""                   using  1:(sqrt($24*$24+$25*$25)) with lines lt 1 lc rgb "midnight-blue" lw 3 title "Forced by SREF mean", \
     ""                   using  1:(sqrt($29*$29+$30*$30)) with lines lt 2 lc rgb "midnight-blue" lw 3 title "Forced by SREF mean + std", \
     ""                   using  1:(sqrt($34*$34+$35*$35)) with lines lt 5 lc rgb "midnight-blue" lw 3 title "Forced by SREF mean - std", \
     "obs-cprg-cur"   using  1:4 with linespoints lw 2 lc rgb "black" notitle, \
     ""               using  1:4 lc rgb "orange" title "Observed" with circles fill solid border lt 1, \
     "single_fort62"  using  1:(sqrt($4*$4+$5*$5)):(sqrt($9*$9+$10*$10))  with filledcurves lc 5 title "Ensemble spread", \
     ""               using  1:(sqrt($4*$4+$5*$5)):(sqrt($14*$14+$15*$15))  with filledcurves lc 5 notitle, \
     ""               using  1:(sqrt($4*$4+$5*$5)):(sqrt($19*$19+$20*$20))  with filledcurves lc 5 notitle, \
     ""               using  1:(sqrt($4*$4+$5*$5)):(sqrt($24*$24+$25*$25))  with filledcurves lc 5 notitle, \
     ""               using  1:(sqrt($4*$4+$5*$5)):(sqrt($29*$29+$30*$30))  with filledcurves lc 5 notitle, \
     ""               using  1:(sqrt($4*$4+$5*$5)):(sqrt($34*$34+$35*$35))  with filledcurves lc 5 notitle, \
     ""               using  1:(sqrt($9*$9+$10*$10)):(sqrt($14*$14+$15*$15))  with filledcurves lc 5 notitle, \
     ""               using  1:(sqrt($9*$9+$10*$10)):(sqrt($19*$19+$20*$20))  with filledcurves lc 5 notitle, \
     ""               using  1:(sqrt($9*$9+$10*$10)):(sqrt($24*$24+$25*$25))  with filledcurves lc 5 notitle, \
     ""               using  1:(sqrt($9*$9+$10*$10)):(sqrt($29*$29+$30*$30))  with filledcurves lc 5 notitle, \
     ""               using  1:(sqrt($9*$9+$10*$10)):(sqrt($34*$34+$35*$35))  with filledcurves lc 5 notitle, \
     ""               using  1:(sqrt($14*$14+$15*$15)):(sqrt($19*$19+$20*$20))  with filledcurves lc 5 notitle, \
     ""               using  1:(sqrt($14*$14+$15*$15)):(sqrt($24*$24+$25*$25))  with filledcurves lc 5 notitle, \
     ""               using  1:(sqrt($14*$14+$15*$15)):(sqrt($29*$29+$30*$30))  with filledcurves lc 5 notitle, \
     ""               using  1:(sqrt($14*$14+$15*$15)):(sqrt($34*$34+$35*$35))  with filledcurves lc 5 notitle, \
     ""               using  1:(sqrt($19*$19+$20*$20)):(sqrt($24*$24+$25*$25))  with filledcurves lc 5 notitle, \
     ""               using  1:(sqrt($19*$19+$20*$20)):(sqrt($29*$29+$30*$30))  with filledcurves lc 5 notitle, \
     ""               using  1:(sqrt($19*$19+$20*$20)):(sqrt($34*$34+$35*$35))  with filledcurves lc 5 notitle, \
     ""               using  1:(sqrt($24*$24+$25*$25)):(sqrt($29*$29+$30*$30))  with filledcurves lc 5 notitle, \
     ""               using  1:(sqrt($24*$24+$25*$25)):(sqrt($34*$34+$35*$35))  with filledcurves lc 5 notitle, \
     ""               using  1:(sqrt($29*$29+$30*$30)):(sqrt($34*$34+$35*$35))  with filledcurves lc 5 notitle, \
     ""               using  1:(sqrt($4*$4+$5*$5))     lt 1 lc 7 lw 2 title "Forced by NAM"  with lines, \
     ""               using  1:(sqrt($9*$9+$10*$10))   lt 1 lc 1 lw 2 title "Forced by GEFS mean"  with lines, \
     ""               using  1:(sqrt($14*$14+$15*$15)) lt 1 lc 3 lw 2 title "Forced by GEFS mean + std"  with lines, \
     ""               using  1:(sqrt($19*$19+$20*$20)) lt 1 lc 4 lw 2 title "Forced by GEFS mean - std"  with lines, \
     ""               using  1:(sqrt($24*$24+$25*$25)) lt 4 lc 1 lw 4 title "Forced by SREF mean"  with lines, \
     ""               using  1:(sqrt($29*$29+$30*$30)) lt 4 lc 3 lw 4 title "Forced by SREF mean + std"  with lines, \
     ""               using  1:(sqrt($34*$34+$35*$35)) lt 4 lc 4 lw 4 title "Forced by SREF mean - std"  with lines, \
     "line-cprg-cur"  using  1:(2*$4) lt 2 lc 7 lw 5 notitle "" with lines, \
     "obs-cprg-cur"   using  1:4 with linespoints lw 2 lc rgb "black" notitle, \
     ""               using  1:4 lc rgb "orange" notitle with circles fill solid border lt 1, \
