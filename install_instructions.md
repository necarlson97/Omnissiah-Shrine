# Omnissiah Shrine — Raspberry Pi Installation Guide

This guide walks you through setting up a **Raspberry Pi** to automatically run the Omnissiah Shrine project on boot, in a kiosk-style configuration.

---

## 1. Hardware Requirements

### Recommended Raspberry Pi Models

- **Raspberry Pi 4 (2GB RAM or higher)**
- Raspberry Pi 5 should also work, but this guide is written and tested against Pi 4

---

### Choosing a MicroSD Card (Important)

Not all MicroSD cards are equal. Since this project is designed to **run continuously**, card quality matters:

16 GB minimum (32 GB recommended)
Class 10 / UHS‑I
(Ideally, a recognizable brand: Samsung, SanDisk, Kingston, etc)

Even still, the card will eventually die, and progress lost. Such is the Omnissiah's will.

## 2. Installing Raspberry Pi OS

### Download Raspberry Pi Imager

On your regular computer (Windows, macOS, or Linux), download the :
[Raspberry Pi Imager](https://www.raspberrypi.com/software/)

### Flash the OS to the MicroSD Card

Insert SD card, open Imager, and follow the steps to install:
**Raspberry Pi OS (64‑bit) — Lite**
(Don't need the desktop version - this project runs without a desktop environment.)

---

### Advanced Options (Highly Recommended)

Before clicking *Write*, open **Advanced Options** (gear icon):

- Set hostname (optional)
- Enable SSH
- Set username and password (default user: `pi` is fine)
- Configure Wi‑Fi
- Set locale and keyboard

Save and write the image.

---

## 3. First Boot & Basic Setup

1. Insert the MicroSD card into the Raspberry Pi
2. Connect:
   - HDMI display
   - Keyboard (temporarily - there is a slot in the side of the case to route your keyboard cable through)
   - Power (for Pi and display)

3. Power on the Pi

Log in when prompted.

---

### Configure Boot Mode

We want the Pi to boot to **console**, not a desktop.

Run:

```bash
sudo raspi-config
```

Navigate to:

- **System Options** → **Boot / Auto Login** → **Console Autologin**

Exit and reboot when prompted.

---

## 4. Install Required System Packages

Update the system:

```bash
sudo apt update
sudo apt upgrade -y
```

Install required packages:

```bash
sudo apt install --no-install-recommends \
  xserver-xorg \
  xinit \
  x11-xserver-utils \
  openbox \
  unclutter \
  alsa-utils
```

### What These Are For (Briefly)

- **Xorg / xinit** — minimal graphics server
- **xrandr** — screen rotation
- **openbox** — lightweight window manager
- **unclutter** — hides the mouse cursor
- **alsa-utils** — audio control

---

## 5. Get the Omnissiah Shrine Project onto the Raspberry Pi

You now need to copy the Omnissiah Shrine project files onto the Raspberry Pi:
either 'cloning' over wifi, or copy/pasting using a thumbstick

---

### Option A — Clone the Repository (Recommended)
On the Raspberry Pi, run:

```bash
cd /home/pi
git clone https://github.com/necarlson97/Omnissiah-Shrine.git
```

This will create the folder:

```text
/home/pi/Omnissiah-Shrine/
```

If `git` is not installed, install it first:

```bash
sudo apt install git
```

---

### Option B — Download ZIP and Transfer via USB

(if you're having trouble with wifi)

#### On your regular computer

1. Go to:
   https://github.com/necarlson97/Omnissiah-Shrine
2. Click **Code → Download ZIP**
3. Extract the ZIP file

You should now have a folder named:

```text
Omnissiah-Shrine/
```

Copy this folder onto a USB thumb drive.

---

#### On the Raspberry Pi

1. Insert the USB drive into the Pi
2. Open a terminal
3. Locate the USB drive (usually auto-mounted under `/media/pi/`):

```bash
ls /media/pi
```

4. Copy the folder to `/home/pi`:

```bash
cp -r /media/pi/<USB_NAME>/Omnissiah-Shrine /home/pi/
```

(Replace `<USB_NAME>` with the actual folder name shown by `ls`.)

---

### Verify the Folder Structure

After copying, confirm the project exists:

```bash
ls /home/pi/Omnissiah-Shrine
```

You should see folders like:

```text
builds/
assets/
README.md
```

Inside the `builds/` folder, you should eventually have:

```text
Omnissiah Shrine.arm64
Omnissiah Shrine.sh
```

---

## 7. Test Manually

Before enabling auto‑start:

```bash
cd /home/pi/Omnissiah-Shrine
./go.sh
```

You should see:

- Screen rotation applied
- Mouse cursor hidden
- Audio enabled
- Omnissiah Shrine launches fullscreen

---

## 8. Enable Auto‑Start on Boot

(you can also view this example service setup [here](https://github.com/necarlson97/Omnissiah-Shrine/blob/master/omnissiah-shrine.service.example))

Create the system service:

```bash
sudo nano /etc/systemd/system/omnissiah-shrine.service
```

Paste:

```ini
# sudo nano /etc/systemd/system/omnissiah-shrine.service
[Unit]
Description=Run Godot Omnissiah Project in Kiosk Mode
After=getty.target

[Service]
# Replace 'pi' with your username if different
User=pi
Group=pi

# Adjust paths as needed
WorkingDirectory=/Omnissiah-Shrine
ExecStart=/Omnissiah-Shrine/go.sh

# If you want the service to auto-restart on crash:
Restart=always
RestartSec=2

# Make sure the standard input is TTY so the console session doesn't end
StandardInput=tty

[Install]
WantedBy=multi-user.target

# Then:
# sudo systemctl daemon-reload
# sudo systemctl enable omnissiah-shrine.service
```

Enable it:

```bash
sudo systemctl daemon-reload
sudo systemctl enable omnissiah-shrine.service
```

---

## 9. Reboot and Verify

```bash
sudo reboot
```

The project should now launch automatically on boot!
The screen will enter an idle state after a min or so, allowing the screen to darken.
(though it does not 'sleep' in the typical manner)

---

## Managing the Service

Check status:

```bash
systemctl status omnissiah-shrine
```

View logs:

```bash
journalctl -u omnissiah-shrine -f
```

Disable auto‑start (for troubleshooting):

```bash
sudo systemctl disable omnissiah-shrine
sudo systemctl stop omnissiah-shrine
```

---

## Troubleshooting (Quick Notes)

- If the screen is black, HDMI output name may differ (`HDMI-0` vs `HDMI-1`)
- If audio is silent, check `alsamixer`
- If X fails to start, confirm `go.sh` runs manually

---

## End

You should now have a fully self‑booting Shrine installation.

Praise the Omnissiah.

