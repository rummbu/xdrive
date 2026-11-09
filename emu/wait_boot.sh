#!/bin/bash
# Wait for the HMI surface, report boot time + render path status.
T0=$(date +%s)
sleep 3
for i in $(seq 240); do grep -q 'visible=1' /srv/mgu22/weston.log 2>/dev/null && break; sleep 1; done
echo "visible after ~$(( $(date +%s) - T0 + 3 ))s (from this script start)"
cat /srv/mgu22/run.log
grep -m1 'visible=1' /srv/mgu22/weston.log
echo "== virgl server =="; tail -5 /srv/mgu22/virgl.log
echo "== hmi gl =="; grep -aiE 'EGL|GL_VERSION|GL_RENDERER|virpipe|vtest' /srv/mgu22/hmi.log | head -8 | cut -c1-220
pgrep -fa Hmi8 >/dev/null && echo "hmi running" || { echo "HMI DIED"; tail -20 /srv/mgu22/hmi.log | cut -c1-200; }
