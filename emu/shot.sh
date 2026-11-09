#!/bin/bash
# Wait for the HMI surface to be visible, let it render, then grab a frame from inside weston.
#   shot.sh <settle-seconds> <max-wait-seconds> <out.png (WSL path)>
SETTLE=${1:-45}; MAX=${2:-600}; OUT=${3:-/srv/mgu22/shots/hmi.png}
RT=/srv/mgu22/root/var/run/wayland
for ((t=0; t<MAX; t+=5)); do
  grep -q 'visible=1' /srv/mgu22/weston.log 2>/dev/null && break
  pgrep -f 'weston.*mgu22' >/dev/null || { [ $t -gt 30 ] && { echo "weston not running"; exit 1; }; }
  sleep 5
done
grep -q 'visible=1' /srv/mgu22/weston.log || { echo "timeout: HMI surface never became visible"; tail -5 /srv/mgu22/run.log; exit 1; }
echo "HMI visible after ${t}s; settling ${SETTLE}s"
sleep "$SETTLE"
mkdir -p "$(dirname "$OUT")"; cd "$(dirname "$OUT")"
rm -f wayland-screenshot-*.png
XDG_RUNTIME_DIR=$RT WAYLAND_DISPLAY=wayland-0 timeout 30 weston-screenshooter 2>&1 | tail -2
f=$(ls -t wayland-screenshot-*.png 2>/dev/null | head -1)
[ -n "$f" ] && mv "$f" "$OUT" && echo "saved $OUT"
