#!/bin/bash

readonly DATE_REFRESH_RATE=1
readonly CPU_TEMP_REFRESH_RATE=5
readonly BATTERY_REFRESH_RATE=5


i=0
cpu_temp=$(sensors | grep CPU | cut -d: -f2 | sed 's/ //g')
cpu_icon=$'\uf4bc'

battery_info=$(upower -i $(upower -e | grep 'BAT'))
read battery state < <(
  echo "$battery_info" | awk '
    /percentage/ { p = $2 }
    /state/     { s = $2 }
    END { print p, s }
  '
)
battery_no_percent=${battery%%%}
battery_icon=$''

date_icon_state=0
date_icon=$'\ue384'

clock_frames=($'\ue381' $'\ue382' $'\ue383' $'\ue384' $'\ue385' $'\ue386' $'\ue387' $'\ue388' $'\ue389' $'\ue38a' $'\ue38b' $'\ue38c')


handle_time_icon() {
   date_icon=${clock_frames[$date_icon_state]}
}

handle_battery_icon() {
   if [ $2 == "charging" ]; then
      battery_icon=$'\U000f0084'
      return
   fi
   if [ $1 -eq 100 ]; then
	   battery_icon=$'\U000f0079'
   elif [ $1 -gt 90 ]; then 
      battery_icon=$'\U000f0082'
   elif [ $1 -gt 80 ]; then
	   battery_icon=$'\U000f0081'
   elif [ $1 -gt 70 ]; then
	   battery_icon=$'\U000f0080'
   elif [ $1 -gt 60 ]; then
	   battery_icon=$'\U000f007f'
   elif [ $1 -gt 50 ]; then
	   battery_icon=$'\U000f007e'
   elif [ $1 -gt 40 ]; then
	   battery_icon=$'\U000f007d'
   elif [ $1 -gt 30 ]; then
	   battery_icon=$'\U000f007c'
   elif [ $1 -gt 20 ]; then
	   battery_icon=$'\U000f007b'
   elif [ $1 -gt 10 ]; then
	   battery_icon=$'\U000f007a'
   fi
}

while :; do
   date=$(date +'%Y-%m-%d %H:%M:%S')
   handle_time_icon "$date_icon_state"

   if [ $((i % $CPU_TEMP_REFRESH_RATE)) == 0 ]; then
	   cpu_temp=$(sensors | grep CPU | cut -d: -f2 | sed 's/ //g')
   fi
   if [ $((i % $BATTERY_REFRESH_RATE)) == 0 ]; then
      battery_info=$(upower -i $(upower -e | grep 'BAT'))
      read battery state < <(
      echo "$battery_info" | awk '
         /percentage/ { p = $2 }
         /state/     { s = $2 }
         END { print p, s }
      '
      )
      battery_no_percent=${battery%%%}
	   handle_battery_icon  "$battery_no_percent" "$state"
   fi
   
   echo "$battery_icon $battery $cpu_icon $cpu_temp $date_icon $date"

   i=$((i+1))
   if [ $date_icon_state -eq 11 ]; then 
      date_icon_state=0
   else
      date_icon_state=$((date_icon_state+1))
   fi   

   sleep 1  
done

