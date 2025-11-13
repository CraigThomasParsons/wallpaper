# Bash Script for Changing Wallpaper on Dual Monitors in Arch Linux with i3wm
These are a bunch of scripts used to setup random wallpaper changes, or wallpaper slideshow

## What it does
1. Wallpaper Daemon: Watches for changes to your wallpaper files and refreshes them with feh.

2. Wallpaper Changer Script: Picks random wallpapers for each monitor and overwrites 001.jpg and 002.jpg.

3. Cron Job: Runs the changer script every 5 minutes.

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
  ~/Pictures/Wallpaper/
├── WideWallpapers/
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

  - I moved the wallpaper watch to this location: 
     The Wallpaper Daemon (./scripts/wallpaper-daemon.sh) to ~/bin/wallpaper-daemon.sh

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
 - It might not always look like this so use the file in this repository


The script picks a random image from each folder and sets it to fill the screen
  (you can tweak the mode if needed).

Bash Script: wallpaper_daemon.sh

Save this as ~/bin/wallpaper_daemon.sh (create the ~/bin dir if needed, and make it executable with 

chmod +x ~/bin/wallpaper_daemon.sh)

# Setting Up as a Systemd User Daemon

We'll create a systemd timer and service to run the script periodically. This acts like a lightweight daemon – it wakes up, runs the script, and sleeps. No constant CPU usage.

Create the service file (defines what to run): mkdir -p ~/.config/systemd/user
    vim ~/.config/systemd/user/wallpaper_daemon.service


.config/systemd/user 
❯ cat wallpaper_daemon.service 

````
[Unit]
Description=My Simple wallpaper changer
After=network.target

[Service]
Type=simple
Environment=DISPLAY=:0
ExecStart=/home/YOURHOMEHERE/bin/wallpaper_daemon.sh

[Install]
WantedBy=default.target
```

The script for changing wallpapers looks a little more complicated.

Find this at:
./scripts/change_wallpaper_files.sh

```
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

Test it: Run ./wallpaper_daemon.sh manually to see if it works.

To edit crontab type:
```
crontab -e
```

If it does then move it to ~/bin as well.
## Since then I took the script that works best for me and saved it as change_wallpaper_files.sh
    */5 * * * *  /home/USERNAME/bin/change_wallpaper_files.sh >> /home/USERNAME/varlog/cronrun.txt

Enable and start:

    systemctl --user daemon-reload
    systemctl --user enable wallpaper-daemon.service
    systemctl --user start wallpaper-daemon.service

Now the files will change every 5 minutes.

✅ How it Works

Every 5 minutes, cron runs random-wallpaper.sh → overwrites 001.jpg & 002.jpg.

The daemon (wallpaper-daemon.sh) detects the file change using inotifywait.

It refreshes your desktop backgrounds with feh.
