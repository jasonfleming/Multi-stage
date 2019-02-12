set term postscript enhanced
set size 2.2,1
set output "EW_cprg_cur.ps"
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
plot "single_fort62_old"  using  1:45:25 with filledcurves lc 9 title "GEFS ensemble spread", \
