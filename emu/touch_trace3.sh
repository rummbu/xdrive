#!/bin/bash
LOG=/srv/mgu22/hmi.log
echo "== last early-video transition states =="
grep -an 'EEarlyVideoTransitionState' $LOG | tail -3 | cut -c1-200
echo "== SYSTEM_EARLY_VIDEO / display property lines =="
grep -aE 'SYSTEM_EARLY_VIDEO_ACTIVE|SYSTEM_DISPLAY|DisplayStateChanged|setDisplayState|display.?state|CID_DISPLAY|displayOn' $LOG | sed 's/^.\{26\}//' | cut -c1-230 | sort | uniq -c | sort -rn | head -25
echo "== property id 0x50007 name? =="
strings -n 6 /srv/mgu22/root/opt/ivi/rootfs/usr/bin/Hmi8 | grep -E '^SYSTEM_(EARLY|DISPLAY|SCREEN|CID|GRAPHIC)' | sort -u | head -30
