# Bash Script for Changing Wallpaper on Dual Monitors in Arch Linux with i3wm
I struggle to get random wallpapers to work well via cronjobs on arch with i3wm.
I can't for some reason get cronjobs to use feh to update my desktop image, no matter what I do.

Today I think I managed to get this to work with help from my friends Perplexity, Grok, ChatGpt

Let’s break this into three parts:

1. Wallpaper Daemon: Watches for changes to your wallpaper files and refreshes them with feh.

2. Wallpaper Changer Script: Picks random wallpapers for each monitor and overwrites 001.jpg and 002.jpg.

3. Cron Job: Runs the changer script every 5 minutes.

A simple Bash script to randomly select and set wallpapers on two monitors from two different folders.
Instructions to set it up as a systemd user service (acting as a daemon) that changes the wallpaper every X minutes (e.g., 30 minutes). This runs in the background without needing a full always-on process.

## Setup Assumptions
- I use Arch Linux + i3wm and if you want to make any use of these scripts you do too.
- feh is installed ( sudo pacman -S feh ).
- inotify-tools is installed for file watching ( sudo pacman -S inotify-tools).
- You have two monitors (e.g., detected as HDMI-1 and DP-1 – check yours with xrandr).
- My main monitor are: a widescreen and my secondary is a vertical widescreen
  DP-3   → wide wallpaper (001.jpg)
  HDMI-1 → vertical wallpaper (002.jpg)

- Wallpapers are stored in two folders:
  $HOME/Pictures/Wallpaper/ (for monitor 1) and $HOME/Pictures/VerticalWallpaper/ (for monitor 2).
```
  ~/PicturesWallpapers/
├── Wallpaper/
│   ├── pic1.jpg
│   ├── pic2.jpg
│   └── ...
├── VerticalWallpaper/
│   ├── vert1.jpg
│   ├── vert2.jpg
│   └── ...
├── CurrentBackground/
│   ├── 001.jpg
│   └── 002.jpg
```

Replace these with your actual paths.
Images are in JPG

The Wallpaper Daemon (~/scripts/wallpaper-daemon.sh)
This script monitors 001.jpg and 002.jpg for changes and refreshes the wallpaper automatically using feh
```
#!/usr/bin/env bash

# Directories and files
WALLPAPER_DIR="$HOME/Wallpapers/current"
FILE1="$WALLPAPER_DIR/001.jpg"
FILE2="$WALLPAPER_DIR/002.jpg"

# Monitors (change to your actual names)
MON1="HDMI-1"
MON2="DP-1"

# Function to set wallpapers
set_wallpapers() {
    feh --no-fehbg --bg-fill "$FILE1" --bg-fill "$FILE2"
}

# Initial setup
set_wallpapers
echo "[daemon] Wallpaper set initially."

# Watch for file changes using inotifywait
while inotifywait -e close_write,create,move_self,delete_self "$FILE1" "$FILE2"; do
    echo "[daemon] Detected wallpaper update, refreshing..."
    set_wallpapers
done
```

The script picks a random image from each folder and sets it to fill the screen
(you can tweak the mode if needed).
Bash Script: wallpaper_daemon.sh
Save this as ~/bin/wallpaper_daemon.sh (create the ~/bin dir if needed, and make it executable with 
chmod +x ~/bin/wallpaper_daemon.sh).

bash
```
#!/bin/bash
#!/usr/bin/env bash
# change_wallpapers.sh

# Set different wallpapers for two monitors using copy. A daemon will use feh to update the background later

# directories containing wallpapers
WALLPAPER_DIR_1="$HOME/Pictures/Wallpaper/*"
WALLPAPER_DIR_2="$HOME/Pictures/VerticalWallpaper/*"

WALLPAPER_1="$HOME/Pictures/CurrentBackground/0001.jpg"
WALLPAPER_2="$HOME/Pictures/CurrentBackground/0002.jpg"

filesWideScreenWallpapers=($WALLPAPER_DIR_1)
countWideScreenWallpapers=${#filesWideScreenWallpapers[@]}

filesVertScreenWallpapers=($WALLPAPER_DIR_2)
countVertScreenWallpapers=${#filesVertScreenWallpapers[@]}

export randomNumFromNumFilesWide=$(shuf -i 0-${countWideScreenWallpapers} -n 1)
export randomNumFromNumFilesVert=$(shuf -i 0-${countVertScreenWallpapers} -n 1)

export wallpaper1=${filesWideScreenWallpapers[${randomNumFromNumFilesWide}]}
export wallpaper2=${filesVertScreenWallpapers[${randomNumFromNumFilesVert}]}

# The vertical wallpapers are handled by Chwall but I might as well randomize this as well.
cp -rf ${wallpaper2} ~/Pictures/CurrentBackground/0002.jpg

# Just agressively copy over the file, because we are getting issues that
# the file doesn't exist.
cp -rf ${wallpaper1} ~/Pictures/CurrentBackground/0001.jpg

# optional logging
echo "$(date): Coppied $wallpaper1 and $wallpaper2 to $HOME/Pictures/CurrentBackground" >> "$HOME/.cache/wallpaper.log"

# Set wallpapers using nitrogen, if you are using nitrogen.
nitrogen --head=0 --set-zoom-fill "$IMAGE1"  # For monitor 1 (head 0)
nitrogen --head=1 --set-zoom-fill "$IMAGE2"  # For monitor 2 (head 1)
```

Test it: Run ./wallpaper_daemon.sh manually to see if it works. If your monitor heads are different, adjust --head=0 and --head=1.

## Since then I took the script that works best for me and saved it as change_wallpaper_files.sh
*/5 * * * *  /home/USERNAME/bin/change_wallpaper_files.sh >> /home/USERNAME/varlog/cronrun.txt

## This is all I actually want to do:
*/5 * * * *  export DISPLAY=:0 && sh -c "feh --bg-fill ~/Pictures/CurrentBackground/0001.jpg --auto-reload --bg-fill ~/Pictures/CurrentBackground/0002.jpg" username

## However that really doesn't actually work!
So I asked Chatgpt and Grok how to proceed and combined my the two solutions and some of my own work together.
I'm still unsure if this actually works

# Setting Up as a Systemd User Daemon

We'll create a systemd timer and service to run the script periodically. This acts like a lightweight daemon – it wakes up, runs the script, and sleeps. No constant CPU usage.

Create the service file (defines what to run): mkdir -p ~/.config/systemd/user
vim ~/.config/systemd/user/wallpaper_daemon.service

Paste this:
[Unit]
Description=Change wallpaper on multiple monitors 
After=network.target

[Service]
Type=simple
Environment=DISPLAY=:0
ExecStart=/home/yourusername/bin/wallpaper_daemon.sh # Replace with your full path Create the timer file (defines the schedule):

[Install]
WantedBy=default.target

vim ~/.config/systemd/user/wallpaper_daemon.timer
Paste this (changes every 30 minutes; adjust as needed):

[Unit] 
Description=Run wallpaper changer every 30 minutes

[Timer]
OnUnitActiveSec=30min # Change interval here (e.g., 1h for hourly)
Persistent=true

[Install]
WantedBy=timers.target

Enable and start:

    systemctl --user daemon-reload
    systemctl --user enable wallpaper_daemon.timer
    systemctl --user start wallpaper_daemon.timer

Check status:

    systemctl --user status wallpaper_daemon.timer
    systemctl --user status wallpaper_daemon.service # After it runs once

This will auto-start on login (since it's a user service).
If you want it to run at boot (even without logging in), enable lingering with loginctl enable-linger yourusername.

To change immediately: systemctl --user start wallpaper_daemon.service.
Logs: Check ~/.wallpaper-log.txt or journalctl --user -u wallpaper_daemon.service.

# Additional Tips
First-time nitrogen setup: Run nitrogen GUI once to configure your monitors if needed (it saves a config in ~/.config/nitrogen/).
If you prefer feh (another option, no GUI needed): Replace the nitrogen lines in the script with feh --bg-fill --no-xinerama "$IMAGE1" --bg-fill --no-xinerama "$IMAGE2", 
but feh's multi-monitor support can be trickier without xinerama disabled.

Edge cases: If your monitors aren't detected properly, use xrandr to confirm outputs and adjust heads. If folders have no images, the script will fail silently – add checks if needed.
Automation on i3 startup: Add exec --no-startup-id wallpaper_daemon.sh to your ~/.config/i3/config to set wallpapers on login.

## The cronjob changes the files often enough, and the script run by the daemon should refresh the desktop.

1️⃣ The Wallpaper Daemon (~/scripts/wallpaper-daemon.sh)

This script monitors 001.jpg and 002.jpg for changes and refreshes the wallpaper automatically using feh.

You'll find this script in scripts/wallpaper-daemon.sh
Make executable 
    chmod +x ~/scripts/wallpaper-daemon.sh

## Run as a background daemon (example using systemd below).
2️⃣ The Wallpaper Changer Script (~/scripts/random-wallpaper.sh)

This script randomly picks one file from each wallpaper directory and overwrites 001.jpg and 002.jpg.
```
#!/usr/bin/env bash

WIDE_DIR="$HOME/Wallpapers/wide"
VERT_DIR="$HOME/Wallpapers/vertical"
CURRENT_DIR="$HOME/Wallpapers/current"

# Choose random wallpapers
WIDE_WP=$(find "$WIDE_DIR" -type f \( -iname "*.jpg" -o -iname "*.png" \) | shuf -n 1)
VERT_WP=$(find "$VERT_DIR" -type f \( -iname "*.jpg" -o -iname "*.png" \) | shuf -n 1)

# Copy to current directory
cp "$WIDE_WP" "$CURRENT_DIR/001.jpg"
cp "$VERT_WP" "$CURRENT_DIR/002.jpg"

echo "[changer] Changed wallpapers at $(date)"
```

## I could have gone with this, instead I used change_wallpaper_files.sh, because I wrote that myself and tested it often enough.
You'll find this script in scripts/wallpaper-daemon.sh
Move it to your local bin director

Make executable
    chmod +x ~/bin/wallpaper-auto-refresh-daemon.sh

Create a systemd user service at:

~/.config/systemd/user/wallpaper-daemon.service

```
Description=Wallpaper auto-refresh daemon
After=graphical-session.target

[Service]
Type=simple
Environment=DISPLAY=:0
ExecStart=%h/bin/wallpaper-auto-refresh-daemon.sh
Restart=always

[Install]
WantedBy=default.target
```

## Enable and start it:

```
systemctl --user enable wallpaper-daemon.service
systemctl --user start wallpaper-daemon.service
```

✅ How it Works

Every 5 minutes, cron runs random-wallpaper.sh → overwrites 001.jpg & 002.jpg.

The daemon (wallpaper-daemon.sh) detects the file change using inotifywait.

It refreshes your desktop backgrounds with feh.
