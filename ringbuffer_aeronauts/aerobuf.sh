#!/usr/bin/bash
#
# Create ionograms without knowledge of ionogram timings. Figure out the timings
# by listening to signals on the antenna.
# 
#
INSTALL_PATH=/home/aeronauts/Documents/GitHub/chirpsounder2_aeronauts

# ram disk buffer for fast i/o.
# if you have a fast SSD or raid, you can also use that
RINGBUFFER_DIR=/dev/sda/hf25
# delete old data from ram disk
rm -Rf $RINGBUFFER_DIR
SAMPLE_RATE=25e6
CENTER_FREQ=12.5e6
CONF_FILE=$INSTALL_PATH/ringbuffer_aeronauts/aerobuf.ini

cd $INSTALL_PATH
mkdir -p logs

# ram disk size. this should be compatible than your ram size
# at least about 2 GB less than the amount of ram available.
RINGBUFFER_SIZE=90000MB

# start ring buffer
drf ringbuffer -z $RINGBUFFER_SIZE $RINGBUFFER_DIR -p 2 > logs/ringbuffer.log 2>&1 &
echo "Starting ringbuffer"

# detect chirps
# two processes seems to be enough to keep up with realtime
python detect_chirps.py $CONF_FILE > logs/detect.log 2>&1 &
echo "Starting detect_chirps.py"

# find timings
python find_timings.py $CONF_FILE > logs/timings.log 2>&1 &
echo "Starting find_timings.py"
# calculate ionograms
# seems like four parallel processes work.
# this means we can process four ionograms simultaneously!
python calc_ionograms.py $CONF_FILE > logs/ionograms.log 2>&1 &

echo "Starting calc_ionograms.py"

# plot ionograms
python plot_ionograms.py $CONF_FILE > logs/plot_ionograms.log &
echo "Starting plot_ionograms.py"

echo "Starting rx_uhd"
while true;
do
    ./rx_uhd --outdir=$RINGBUFFER_DIR > logs/thor.log 2>&1 
    sleep 5
done

