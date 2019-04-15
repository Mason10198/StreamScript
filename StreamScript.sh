#!/bin/bash

### Info / Config ###
title=StreamScript # Title to display
version=v0.2 # Version to display
stream=rtmp://192.168.1.4/live/tv # Stream URL to connect
delay=30 # Delay (secs) between connection attempts
startdelay=3s # Startup delay (specify unit)
failtimeout=35 # Connection duration (secs) less than this counts as fail
log=/home/pi/streamscript.log # Location & name of logfile

function show_time () {
    num=$1
    min=0
    hour=0
    day=0
    if((num>59));then
        ((sec=num%60))
        ((num=num/60))
        if((num>59));then
            ((min=num%60))
            ((num=num/60))
            if((num>23));then
                ((hour=num%24))
                ((day=num/24))
            else
                ((hour=num))
            fi
        else
            ((min=num))
        fi
    else
        ((sec=num))
    fi
    echo $hour"h:"$min"m:"$sec"s:"
}

echo $title" "$version" starting in "$startdelay"..."
startdate=`date +"%R %A, %B %d"`
succ=0
fail=0
lastdur="None yet..."
sleep $startdelay

while :
do

clear
tput civis
date=`date`
echo ""$title" "$version" | "`date +"%R %A, %B %d"`" | Created by Mason Nelson"
printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
echo "Client hostname: "`hostname`
echo "Client IP: "`hostname -I`
echo "Stream URL: "$stream
echo "Last startup: "$startdate
echo "Successful attempts: "$succ
echo "Failed attempts: "$fail
echo "Last successful connection duration: "$lastdur
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
convtime=`show_time $time`

if [ $time -lt $failtimeout ]; then
  let "fail++"
  echo "FAIL: attempt "$NUM" @ "$date >> $log
  printf "\rConnection failed."
else
  let "succ++"
  echo "SUCCESS: attempt "$NUM" @ "$date >> $log
  echo "Duration: "$convtime >> $log
  printf "\rConnection successful."
  lastdur=$convtime
fi

wait_time=$delay

printf "\nDuration: "$convtime
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
