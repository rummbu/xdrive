#!/bin/bash
export XDG_RUNTIME_DIR=/srv/mgu22/root/var/run/wayland WAYLAND_DISPLAY=wayland-0
timeout 6 weston-debug proto > /tmp/proto.txt 2>&1 &
sleep 1
echo 'tap 960 596' > /srv/mgu22/input.fifo
wait
echo "lines: $(wc -l < /tmp/proto.txt)"
grep -E 'wl_pointer|wl_seat|wl_touch' /tmp/proto.txt | head -20
echo "== scene graph =="
timeout 3 weston-debug scene-graph 2>&1 | grep -E 'View|position|layer|surface|input|Layer' | head -40
