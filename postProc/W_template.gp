set grid
set xlabel "Date/Time %timezone% (mm/dd-HH:MM)"
set xdata time
set format x "%m/%d-%H:%M"
set xtics 86400
set mxtics 12
set key top left box
set datafile missing "-99999"
set timefmt "%Y-%m-%d %H:%M:%S"
set yrange [%ymin%:%ymax%]
#
set ylabel "%ylabel%"
unset key
# 
# count the number of non-missing values
count1(fname)=system(sprintf("awk 'NR>2 && $%col%!=-99999 { print $0 }' %s | wc -l",fname))
k=count1("%transpose%")
#
# if this column consists of only missing values, write a message but
# don't plot anything; only pretend to plot something so that we get the
# right time range across the bottom; if there are real values, plot them
if ( k==0 ) \
   set label 1 "no data here" at graph 0.5, graph 0.5; \
   plot "%transpose%" using 1:1 title "";  \
else \
set style line 2 lt 1 lc rgb "#FF0000" lw 2 pt 11 ps 1.5
plot "%transpose%" using 1:%col% w lp ls 2 title "predicted",
