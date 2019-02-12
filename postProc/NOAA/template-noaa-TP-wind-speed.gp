set term postscript enhanced
set output "Trident_speed.ps"
set size 2.2,1
set terminal postscript "TimesRoman" 20
set title "Trident Pier (NOAA station 80.594W 28.417N) \n\n        Validation cycle: %oldcycle%                                                                                               Current cycle: %cycle%                                                      "
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
set ylabel "Wind velocity speed (m/s)"
#count1(fname)=system(sprintf("awk 'NR>2 && $6!=-99999.0000 { print $0 }' %s | wc -l",fname))
#k=count1("obs-cprg-trim")
#
# if this column consists of only missing values, write a message but
# don't plot anything; only pretend to plot something so that we get the
# right time range across the bottom; if there are real values, plot them
set style circle radius 1500
plot "single_fort72_old"  using  1:(sqrt($13*$13+$14*$14)):(sqrt($20*$20+$21*$21))   with filledcurves lc 9 title "GEFS ensemble spread", \
     ""                   using  1:(sqrt($13*$13+$14*$14)):(sqrt($27*$27+$28*$28))   with filledcurves lc 9 notitle, \
     ""                   using  1:(sqrt($20*$20+$21*$21)):(sqrt($27*$27+$28*$28)) with filledcurves lc 9 notitle, \
     ""                   using  1:(sqrt($34*$34+$35*$35)):(sqrt($41*$41+$42*$42)) lt rgb "#2F4F4F" with filledcurves title "SREF ensemble spread", \
     ""                   using  1:(sqrt($48*$48+$49*$49)):(sqrt($48*$48+$49*$49)) lt rgb "#2F4F4F" with filledcurves notitle, \
     ""                   using  1:(sqrt($41*$41+$42*$42)):(sqrt($48*$48+$49*$49)) lt rgb "#2F4F4F" with filledcurves notitle, \
     ""                   using  1:(sqrt($6*$6+$7*$7))     with lines lt 1 lc 7 lw 3 title "Forced by NAM", \
     ""                   using  1:(sqrt($13*$13+$14*$14))   with lines lt 1 lc rgb "gray20" lw 3 title "Forced by GEFS mean", \
     ""                   using  1:(sqrt($20*$20+$21*$21)) with lines lt 2 lc rgb "gray20" lw 3 title "Forced by GEFS mean + std", \
     ""                   using  1:(sqrt($27*$27+$28*$28)) with lines lt 5 lc rgb "gray20" lw 3 title "Forced by GEFS mean - std", \
     ""                   using  1:(sqrt($34*$34+$35*$35)) with lines lt 1 lc rgb "midnight-blue" lw 3 title "Forced by SREF mean", \
     ""                   using  1:(sqrt($41*$41+$42*$42)) with lines lt 2 lc rgb "midnight-blue" lw 3 title "Forced by SREF mean + std", \
     ""                   using  1:(sqrt($48*$48+$49*$49)) with lines lt 5 lc rgb "midnight-blue" lw 3 title "Forced by SREF mean - std", \
     "wind-8721604-trimmed"   every 3::3 using  1:3 with linespoints lw 2 lc rgb "black" notitle, \
     ""               every 3::3 using  1:3 lc rgb "orange" title "Observed" with circles fill solid border lt 1, \
     "single_fort72"  using  1:(sqrt($6*$6+$7*$7)):(sqrt($13*$13+$14*$14))  with filledcurves lc 5 title "Ensemble spread", \
     ""               using  1:(sqrt($6*$6+$7*$7)):(sqrt($20*$20+$21*$21))  with filledcurves lc 5 notitle, \
     ""               using  1:(sqrt($6*$6+$7*$7)):(sqrt($27*$27+$28*$28))  with filledcurves lc 5 notitle, \
     ""               using  1:(sqrt($6*$6+$7*$7)):(sqrt($34*$34+$35*$35))  with filledcurves lc 5 notitle, \
     ""               using  1:(sqrt($6*$6+$7*$7)):(sqrt($41*$41+$42*$42))  with filledcurves lc 5 notitle, \
     ""               using  1:(sqrt($6*$6+$7*$7)):(sqrt($48*$48+$49*$49))  with filledcurves lc 5 notitle, \
     ""               using  1:(sqrt($13*$13+$14*$14)):(sqrt($20*$20+$21*$21))  with filledcurves lc 5 notitle, \
     ""               using  1:(sqrt($13*$13+$14*$14)):(sqrt($27*$27+$28*$28))  with filledcurves lc 5 notitle, \
     ""               using  1:(sqrt($13*$13+$14*$14)):(sqrt($48*$48+$49*$49))  with filledcurves lc 5 notitle, \
     ""               using  1:(sqrt($13*$13+$14*$14)):(sqrt($41*$41+$42*$42))  with filledcurves lc 5 notitle, \
     ""               using  1:(sqrt($13*$13+$14*$14)):(sqrt($48*$48+$49*$49))  with filledcurves lc 5 notitle, \
     ""               using  1:(sqrt($20*$20+$21*$21)):(sqrt($27*$27+$28*$28))  with filledcurves lc 5 notitle, \
     ""               using  1:(sqrt($20*$20+$21*$21)):(sqrt($48*$48+$49*$49))  with filledcurves lc 5 notitle, \
     ""               using  1:(sqrt($20*$20+$21*$21)):(sqrt($41*$41+$42*$42))  with filledcurves lc 5 notitle, \
     ""               using  1:(sqrt($20*$20+$21*$21)):(sqrt($48*$48+$49*$49))  with filledcurves lc 5 notitle, \
     ""               using  1:(sqrt($27*$27+$28*$28)):(sqrt($34*$34+$35*$35))  with filledcurves lc 5 notitle, \
     ""               using  1:(sqrt($27*$27+$28*$28)):(sqrt($41*$41+$42*$42))  with filledcurves lc 5 notitle, \
     ""               using  1:(sqrt($27*$27+$28*$28)):(sqrt($48*$48+$49*$49))  with filledcurves lc 5 notitle, \
     ""               using  1:(sqrt($34*$34+$35*$35)):(sqrt($41*$41+$42*$42))  with filledcurves lc 5 notitle, \
     ""               using  1:(sqrt($34*$34+$35*$35)):(sqrt($48*$48+$49*$49))  with filledcurves lc 5 notitle, \
     ""               using  1:(sqrt($41*$41+$42*$42)):(sqrt($48*$48+$49*$49))  with filledcurves lc 5 notitle, \
     ""               using  1:(sqrt($6*$6+$7*$7))     lt 1 lc 7 lw 2 title "Forced by NAM"  with lines, \
     ""               using  1:(sqrt($13*$13+$14*$14))   lt 1 lc 1 lw 2 title "Forced by GEFS mean"  with lines, \
     ""               using  1:(sqrt($20*$20+$21*$21)) lt 1 lc 3 lw 2 title "Forced by GEFS mean + std"  with lines, \
     ""               using  1:(sqrt($27*$27+$28*$28)) lt 1 lc 4 lw 2 title "Forced by GEFS mean - std"  with lines, \
     ""               using  1:(sqrt($34*$34+$35*$35)) lt 4 lc 1 lw 4 title "Forced by SREF mean"  with lines, \
     ""               using  1:(sqrt($41*$41+$42*$42)) lt 4 lc 3 lw 4 title "Forced by SREF mean + std"  with lines, \
     ""               using  1:(sqrt($48*$48+$49*$49)) lt 4 lc 4 lw 4 title "Forced by SREF mean - std"  with lines, \
     "line-TP-wind"   using  1:4 lt 2 lc 7 lw 5 notitle "" with lines, \
     "wind-8721604-trimmed"   every 3::3 using  1:3 with linespoints lw 2 lc rgb "black" notitle, \
     ""               using  1:3 every 3::3  lc rgb "orange" notitle with circles fill solid border lt 1, \
