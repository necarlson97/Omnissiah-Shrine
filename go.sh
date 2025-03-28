#!/usr/bin/env bash
# Script to launch the build in a GIU on the rpi terminal mode
xrandr --output HDMI-1 --rotate inverted
amixer set Master 100% unmute

startx /home/pi/Omnissiah-Shrine/builds/Omnissiah\ Shrine.sh -- :0
