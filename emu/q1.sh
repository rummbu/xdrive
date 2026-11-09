#!/bin/bash
Q="$(cat /srv/mgu22/repo_root)/emu/caf_q.sh"
tr -d '\r' < "$Q" > /tmp/caf_q.sh
bash /tmp/caf_q.sh '^(SERIES|BRAND|MARKE|.*BAUREIHE.*|VEHICLE_TYPE|CID_DISPLAY.*|.*DISPLAY_RES.*|.*DISPLAY_SIZE.*|HMI_ID.*|TRIM.*|.*COLOR.*|.*PAINT.*|.*LACK.*|.*MOTORSPORT.*|.*BMWM.*|.*_BRAND.*)$' 0
echo "== txt values for these =="
grep -nE '^"(SERIES|BRAND|.*DISPLAY_RES.*|.*DISPLAY_SIZE.*|HMI_ID.*|.*BRAND.*|TRIM.*|.*COLOR.*)"' /srv/mgu22/root/opt/ivi/rootfs/usr/share/hmi/data/ro/MGU22_Coding.txt | head -30
echo "== txt flag count =="; grep -cE '^"[A-Z0-9_]+":' /srv/mgu22/root/opt/ivi/rootfs/usr/share/hmi/data/ro/MGU22_Coding.txt
