#!/bin/bash

### Info / Config ###
title=StreamScript                                    # Title to display
version=v0.3                                          # Version to display
stream=rtmp://192.168.1.9/live/tv                     # Stream URL to connect
delay=30                                              # Delay (secs) between connection attempts
startdelay=3s                                         # Startup delay (specify unit)
failtimeout=35                                        # Connection duration (secs) less than this counts as fail
log=/home/pi/StreamScript/streamscript.log            # Location & name of logfile

echo $title" "$version" starting in "$startdelay"..." # Display startup message in console
startdate=$(date +"%R %A, %B %d")
succ=0
fail=0
lastdur="None yet..." # Last succsessful connection duration; starts empty
sleep $startdelay     # Startup delay

while :; do # Program core loop execution
  draw_status
  omxplayer -o hdmi --live $stream >/dev/null &# OMXPlayer stream command

  # Spinning progress indicator
  pid=$! # Process ID of OMXPlayer
  time=0
  spin='-\|/'
  i=0

  while kill -0 $pid 2>/dev/null; do
    i=$(((i + 1) % 4))
    printf "\rSearching for stream... ${spin:$i:1}"
    sleep .1
    let "time++"
  done

  time=$((time / 10))
  convtime=$(show_time $time)

  if [ $time -lt $failtimeout ]; then
    let "fail++"
    echo "FAIL: attempt "$((succ + fail))" @ "$date >>$log
    printf "\rConnection failed.            "
  else
    let "succ++"
    echo "SUCCESS: attempt "$((succ + fail))" @ "$date >>$log
    echo "Duration: "$convtime >>$log
    printf "\rConnection successful. Stream has now ended or lost connection."
    printf "\nDuration: "$convtime
    lastdur=$convtime
  fi

  echo ""
  echo ""
  temp_cnt=${delay}
  dots=""

  while [[ ${temp_cnt} -gt 0 ]]; do
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

function draw_status() {
  clear                                                                                                                                                              # Clear console
  tput civis                                                                                                                                                         # Make cursor invisible
  date=$(date)                                                                                                                                                       # Current date
  echo -e "\033[1;32m"$title" "$version" | "$(date +"%R %A, %B %d")" | Created by Mason Nelson\033[0m"                                                               # Title line
  printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -                                                                                                            # Draw horizontal divider
  echo "CPU Temp: "$(($(cat /sys/class/thermal/thermal_zone0/temp) / 1000))"*C | GPU Temp: "$(/opt/vc/bin/vcgencmd measure_temp | tr -d 'temp=' | cut -f1 -d".")"*C" # CPU & GPU temps
  echo "Client hostname: "$(hostname)                                                                                                                                # Hostname of device running this script
  echo "Client IP: "$(hostname -I)                                                                                                                                   # IP of device running this script
  echo "Stream URL: "$stream
  printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
  echo "Started at: "$startdate
  echo "Successful attempts: "$succ
  echo "Failed attempts: "$fail
  echo "Last successful connection duration: "$lastdur
  printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
  echo ""
}

function show_time() { # Function to convert seconds to human-readable time format
  num=$1
  min=0
  hour=0
  day=0
  if ((num > 59)); then
    ((sec = num % 60))
    ((num = num / 60))
    if ((num > 59)); then
      ((min = num % 60))
      ((num = num / 60))
      if ((num > 23)); then
        ((hour = num % 24))
        ((day = num / 24))
      else
        ((hour = num))
      fi
    else
      ((min = num))
    fi
  else
    ((sec = num))
  fi
  echo $hour"h:"$min"m:"$sec"s"
}
