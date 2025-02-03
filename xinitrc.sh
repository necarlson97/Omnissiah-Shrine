#!/usr/bin/env bash
# Example of an '.xinitrc' file that could be used to launch the project
# as a local web build, then display in a chromium kiosk

# 1) Start the Python server for our Godot HTML5 build
#    We'll assume it's not already running in the background.
#    If you always want it to restart, unconditionally call the script:
#    Or put the commands inline here.

cd /Omnissiah-Shrine/builds/web
python3 -m http.server 8000 &

# Give the server a moment to start
sleep 1

# 2) Start openbox (lightweight window manager)
openbox-session &

# 4) Launch Chromium in kiosk mode, pointing at the local web server
chromium-browser --kiosk \
  --disable-translate \
  --noerrdialogs \
  --disable-infobars \
  --start-fullscreen \
  http://localhost:8000

# Hide the mouse cursor, you could install "unclutter":
unclutter -idle 0.5 &