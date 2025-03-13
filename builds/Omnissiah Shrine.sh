#!/bin/sh
xrandr --output HDMI-1 --rotate inverted
amixer set Master 100% unmute

echo -ne '\033c\033]0;Omnissiah Shrine\a'
base_path="$(dirname "$(realpath "$0")")"
"$base_path/Omnissiah Shrine.arm64" "$@"
