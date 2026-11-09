#!/bin/bash
tail -8 /srv/mgu22/weston.log
echo "== hmi pointer/touch lines =="
grep -acE 'mouseButton|CHmiWindowInputHandler' /srv/mgu22/hmi.log
grep -aE 'CHmiWindowInputHandler|mouseButton|forwardTouchData\] Touch' /srv/mgu22/hmi.log | tail -5 | cut -c1-230
echo "== hmi alive / log size =="
pgrep -fa Hmi8 | cut -c1-80; ls -la /srv/mgu22/hmi.log; tail -2 /srv/mgu22/hmi.log | cut -c1-200
echo "== screenshooter =="
cd /tmp; XDG_RUNTIME_DIR=/srv/mgu22/root/var/run/wayland WAYLAND_DISPLAY=wayland-0 timeout 30 weston-screenshooter; echo "rc=$?"; ls /tmp/wayland-screenshot* 2>&1 | tail -2
