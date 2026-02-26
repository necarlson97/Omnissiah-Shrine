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
(Tested on Bookworm / Trixie)
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

For the purposes of this guide, the default Raspberry Pi OS username is assumed to be:

```
pi
```

If your username is different, later on, you'll need to replace `pi` with your username in all paths and commands (especially `/home/pi/...`).

You can later verify your current username with:

```
whoami
```

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

If you are using an HDMI screen with audio (as I am), you'll also need:

- **System Options** → **Audio** → **HDMI 0**

Exit and reboot when if prompted.

You can also verify volume levels with:

```
alsamixer
```


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
  alsa-utils \
  git
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

## 7. Test Manually (From SSH)

If you are connected via SSH, you cannot run `./go.sh` directly because `startx` requires a real virtual terminal.

Instead, run:

```
sudo openvt -c 1 -s -f -- bash -lc 'cd /home/pi/Omnissiah-Shrine && ./go.sh'
```

This launches the shrine on virtual terminal 1.

If you are physically at the Raspberry Pi with keyboard + monitor attached, you can instead run:

```
cd /home/pi/Omnissiah-Shrine
./go.sh
```

You should see:

- Screen rotation applied
- Mouse cursor hidden
- Audio enabled
- Omnissiah Shrine launches fullscreen

---

## 8. Enable Auto-Start on Boot (Modern Raspberry Pi OS)

Modern Raspberry Pi OS (Bookworm / Trixie) requires X to run inside a real login session.
We accomplish this by auto-logging into `tty1` and launching the shrine from `.bash_profile`.

### Step 1 — Enable Autologin on tty1

```
sudo systemctl edit getty@tty1.service
```

Paste:

```
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin pi --noclear %I $TERM
Type=idle
```

Then reload:

```
sudo systemctl daemon-reload
```

---

### Step 2 — Create `.bash_profile`

```
nano /home/pi/.bash_profile
```

Add:

```
# Auto-start Omnissiah Shrine on tty1 only
if [ "$(tty)" = "/dev/tty1" ] && [ -z "$DISPLAY" ]; then
  cd /home/pi/Omnissiah-Shrine
  exec ./go.sh
fi
```

Save and reboot:

```
sudo reboot
```

The shrine should now start automatically on boot.
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

