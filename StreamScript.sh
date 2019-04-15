#!/bin/bash

### Info / Config ###
title=StreamScript # Title to display
version=v0.2 # Version to display
stream=rtmp://192.168.1.4/live/tv # Stream URL to connect
delay=30 # Delay (secs) between connection attempts
startdelay=10s # Startup delay (specify unit)
failtimeout=35 # Connection duration (secs) less than this counts as fail
log=/home/pi/StreamScript/streamscript.log # Location & name of logfile

echo $title" "$version" starting in 10 seconds..."
startdate=`date +"%R %A, %B %d"`
succ=0
fail=0
sleep $startdelay

while :
do

clear
tput civis
date=`date`
echo ""$title" "$version" | "`date +"%R %A, %B %d"`" | Created by Mason Nelson"
printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
echo ""
echo "Client Hostname: "`hostname`
echo "Client IP: "`hostname -I`
echo "Stream URL: "$stream
echo "Successful attempts: "$succ
echo "Failed attempts: "$fail
printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
echo ""

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

time=$((time / 10))

if [ $time -lt $failtimeout ]; then
  let "fail++"
  echo "FAIL: attempt "$NUM" @ "$date >> $log
else
  let "succ++"
  echo "SUCCESS: attempt "$NUM" @ "$date >> $log
  echo "Duration: "$((time / 60))" mins "$((time % 60))" secs" >> $log
fi

wait_time=$delay

printf "\rStream disconnected or not found."
#printf "\nConnection duration: "$((time / 60))" mins "$((time % 60))" secs."
printf "\nConnection duration: "`displaytime $time`
echo ""
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

function displaytime {
  local T=$1
  local D=$((T/60/60/24))
  local H=$((T/60/60%24))
  local M=$((T/60%60))
  local S=$((T%60))
  (( $D > 0 )) && printf '%d days ' $D
  (( $H > 0 )) && printf '%d hours ' $H
  (( $M > 0 )) && printf '%d minutes ' $M
  (( $D > 0 || $H > 0 || $M > 0 )) && printf 'and '
  printf '%d seconds\n' $S
}
