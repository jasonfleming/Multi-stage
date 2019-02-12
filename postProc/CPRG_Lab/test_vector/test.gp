set term postscript enhanced 
set output "wind.ps"
set terminal postscript "TimesRoman" 15
set title "Wind vector test"                                                              
set grid
set xdata time
set format x "%m/%d-%H:%M"
set xtics 86400
set mxtics 12
#set key outside bottom horizontal center
set datafile missing "-99999"
set timefmt "%Y-%m-%d %H:%M:%S"
set yrange [:]
set autoscale xfix
set ylabel "wind speed and direction"    
# if this column consists of only missing values, write a message but
# don't plot anything; only pretend to plot something so that we get the
# right time range across the bottom; if there are real values, plot them
plot "obs-cprg-wind"  using  1:4 lt 4 lc 1 lw 4 with lines, \
                  ""  using  1:4:(-$4*cos($5)):(-$4*sin($5)) w vectors lw 2 lt 2
