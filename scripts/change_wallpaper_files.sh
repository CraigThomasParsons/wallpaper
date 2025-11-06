#!/usr/bin/env bash
# change_wallpapers.sh

# Set different wallpapers for two monitors using copy.
# A daemon will use feh to update the background later

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
echo "[changer] Changed wallpapers at $(date)"
