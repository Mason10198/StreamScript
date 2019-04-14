#!/bin/bash

### Info / Config ###
title=StreamScript # Title to display
version=v0.2 # Version to display
stream=rtmp://192.168.1.4/live/tv # Stream URL to connect
delay=30 # Delay (secs) between connection attempts
startdelay=10s # Startup delay (specify unit)
log=/home/pi/streamscript.log # Location & name of logfile

echo $title" "$version" starting in 10 seconds..."
date2=`date +"%R %A, %B %d"`
succ=0
fail=0
sleep $startdelay

while :
do

clear
tput civis
date=`date`
echo $title" "$version" | "$date2
echo "Stream: "$stream
echo "-Connection attempts since boot-"
echo "Successful: "
echo "Failed: "
printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' - # Draw horizontal line
echo ""

echo "Attempt "$NUM" @ "$date >> $log # Write simple log

omxplayer -o hdmi --live $stream > /dev/null & # OMXPlayer stream command

# Spinning progress indicator
pid=$! # Process Id of OMXPlayer
time=0
spin='-\|/'

i=0
while kill -0 $pid 2>/dev/null
do
  i=$(( (i+1) %4 ))
  printf "\rSearching for stream... ${spin:$i:1}"
  sleep .1
  let "time++"
done

wait_time=$delay

printf "\rStream disconnected or not found. Time: "$((time / 10))
echo ""
temp_cnt=${wait_time}
dots=""
while [[ ${temp_cnt} -gt 0 ]];
do
    LEN=$(echo ${#dots})
 
    if [ $LEN -ge 3 ]; then
        printf "\rRetrying in %2d seconds   "
        dots=""
    else
        dots=$dots"."
    fi
    printf "\rRetrying in %2d seconds"$dots ${temp_cnt}
    sleep 1
    ((temp_cnt--))
done
echo ""
done
