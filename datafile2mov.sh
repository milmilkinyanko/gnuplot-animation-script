#!/bin/bash

DATAFILE=$1
lines=$(cat $DATAFILE | wc -l)

# to avoid overwriting
output_fname_gif="${DATAFILE%.dat}.gif"
output_fname_mp4="${DATAFILE%.dat}.mp4"

echo "datafile: $DATAFILE"
echo "converted gif: $output_fname_gif"
echo "converted mp4: $output_fname_mp4"
echo "start gnuplot"

# create gif animation with gnuplot
# val=...: read line (NR == i)
# second plotted data and third one are data sequence point and bar.
/usr/bin/gnuplot -e "
    set term gif animate optimize delay 1 size 960,720;
    set output '$output_fname_gif';
    set xrange [-3:3];
    set yrange [-1:1];
    set grid x,y,mx,my;
    set samples 1000;
    filedata = '$DATAFILE';
    line_num = real($lines);
    do for [i=1:line_num] {
        set parametric;
        set trange[-1:1];
        val = real(system(sprintf('awk ''{if (NR == %d) print \$1 }'' %s', i, filedata)));
        plot filedata u 1:2 w l lw 2 title \"data plot\",\
              filedata u 1:2 every ::i::i w p pt 7 ps 2 title \"\",\
              val,t w l lw 2 title \"\";
    };
    set out;
    set terminal wxt enhanced;
"

echo "finish gnuplot"

# SAMPLING_PERIOD: data sampling period
SAMPLING_PERIOD=10 # msec
SPEED=$(echo "scale=5; 1000.0 / $SAMPLING_PERIOD / 10.0" | bc) # for adjusting play speed

echo "SAMPLING PERIOD: $SAMPLING_PERIOD"
echo "play speed: x$SPEED"
echo "start ffmpeg"
ffmpeg -i $output_fname_gif -vf setpts=PTS/$SPEED -r 30 $output_fname_mp4
echo "finish ffmpeg"
