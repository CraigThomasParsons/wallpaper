#!/usr/bin/env bash
# Refresh the current background.

# Directories and files
WALLPAPER_DIR="$HOME/Wallpapers/CurrentBackground"
FILE1="$WALLPAPER_DIR/0001.jpg"
FILE2="$WALLPAPER_DIR/0002.jpg"

# Function to set wallpapers
set_wallpapers() {
    DISPLAY=:0 && feh --auto-reload --bg-fill $HOME/Pictures/CurrentBackground/0001.jpg --auto-reload --bg-fill $HOME/Pictures/CurrentBackground/0002.jpg
}

# Initial setup
set_wallpapers
echo "[daemon] Wallpaper set initially."

# Watch for file changes using inotifywait
while inotifywait -e close_write,create,move_self,delete_self "$FILE1" "$FILE2"; do
    echo "[daemon] Detected wallpaper update, refreshing..."
    set_wallpapers
done