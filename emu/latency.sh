#!/bin/bash
# Tap, then grab frames at fixed delays to see how fast the screen reacts.
#   latency.sh X Y name delay1 [delay2 ...]
X=$1; Y=$2; N=$3; shift 3
RT=/srv/mgu22/root/var/run/wayland
OUT="$(cat /srv/mgu22/repo_root)/screenshots"
echo "tap $X $Y" > /srv/mgu22/input.fifo
T0=$(date +%s.%N); prev=0
for d in "$@"; do
  sleep $(echo "$d - $prev" | bc); prev=$d
  ( cd /tmp && rm -f wayland-screenshot-*.png && XDG_RUNTIME_DIR=$RT WAYLAND_DISPLAY=wayland-0 timeout 10 weston-screenshooter >/dev/null 2>&1 && mv wayland-screenshot-*.png "$OUT/${N}_${d}s.png" )
  echo "frame @${d}s -> ${N}_${d}s.png (taken at +$(echo "$(date +%s.%N) - $T0" | bc | cut -c1-4)s)"
done
