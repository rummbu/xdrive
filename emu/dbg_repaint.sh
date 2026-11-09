#!/bin/bash
W=$(pgrep -f 'weston.*mgu22' | head -1)
echo "weston pid=$W state=$(awk '{print $3}' /proc/$W/stat) wchan=$(cat /proc/$W/wchan)"
for t in /proc/$W/task/*; do echo "  $(cat $t/comm) $(awk '{print $3}' $t/stat) $(cat $t/wchan)"; done
echo "== HMI renderer frame stats (last) =="
grep -a 'RPER' /srv/mgu22/hmi.log | tail -3 | cut -c1-250
echo "== weston debug scopes =="
WAYLAND_DEBUG=0 XDG_RUNTIME_DIR=/srv/mgu22/root/var/run/wayland WAYLAND_DISPLAY=wayland-0 timeout 5 weston-debug -l 2>&1 | head -20
