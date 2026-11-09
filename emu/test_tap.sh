#!/bin/bash
# Wait for the UI, inject a tap with a protocol trace running, report what the HMI saw.
#   test_tap.sh X Y [settle]
X=${1:-960}; Y=${2:-596}; S=${3:-25}
for i in $(seq 100); do grep -q 'visible=1' /srv/mgu22/weston.log && break; sleep 3; done
sleep $S
export XDG_RUNTIME_DIR=/srv/mgu22/root/var/run/wayland WAYLAND_DISPLAY=wayland-0
timeout 5 weston-debug proto > /tmp/proto.txt 2>&1 &
sleep 1
echo "tap $X $Y" > /srv/mgu22/input.fifo
wait
echo "== proto (pointer) =="; grep -E 'wl_pointer' /tmp/proto.txt | head -12
echo "== weston =="; grep mgu-ivi /srv/mgu22/weston.log | tail -2
sleep 4
echo "== hmi =="
grep -aE 'CHmiWindowInputHandler|forwardTouchData\] Touch|Handled in|Touch event handled' /srv/mgu22/hmi.log | tail -8 | cut -c60-240
