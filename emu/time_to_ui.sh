#!/bin/bash
# When does the HMI show real content? (screenshot PNG > 60 KB; a black frame is ~5 KB)
RT=/srv/mgu22/root/var/run/wayland
for i in $(seq 120); do
  cd /tmp; rm -f wayland-screenshot-*.png
  XDG_RUNTIME_DIR=$RT WAYLAND_DISPLAY=wayland-0 timeout 10 weston-screenshooter >/dev/null 2>&1
  f=$(ls wayland-screenshot-*.png 2>/dev/null | head -1)
  s=$([ -n "$f" ] && stat -c %s "$f" || echo 0)
  [ "$s" -gt 60000 ] && { echo "UI content at $(date +%T.%N | cut -c1-12) (png $s bytes)"; break; }
  sleep 1
done
echo "weston started: $(grep -m1 -oE '^\[[0-9:.]+\]' /srv/mgu22/weston.log)"
echo "surface visible: $(grep -m1 'visible=1' /srv/mgu22/weston.log | cut -c1-15)"
