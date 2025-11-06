#!/usr/bin/env bash
inotifywait -q -m -e close_write ~/Pictures/CurrentBackground/0001.jpg
while read -r filename event; do
  export DISPLAY=":0"
  export XAUTHORITY=$(ls -1 /tmp/xauth*)
  sh -c "feh --bg-fill ~/Pictures/CurrentBackground/0001.jpg --auto-reload --bg-fill ~/Pictures/CurrentBackground/0002.jpg" YOURNAME
  sh -c "/home/YOURNAME/scripts/wallpapers/runFeh.sh" YOURNAME
  echo "Change in 0002.jpg detected trying to update wallpapers to CurrentBackground" >> /home/YOURNAME/varlog/cronrun.txt
done
