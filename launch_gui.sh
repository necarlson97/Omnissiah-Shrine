#!/usr/bin/env bash
# Called within a 'startx' - so it can invert the screen
xrandr --output HDMI-1 --rotate inverted
amixer set Master 100% unmute
"/home/pi/Omnissiah-Shrine/builds/Omnissiah Shrine.sh"