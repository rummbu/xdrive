#!/bin/bash
H=/srv/mgu22/root/opt/ivi/rootfs/usr/bin/Hmi8
strings -n 6 $H | grep -iE 'EarlyHmi|EARLY_HMI|earlyhmi.*timeout|HmiTimeout' | sort -u | head -30
echo "== symbols =="
aarch64-linux-gnu-nm -DC $H | grep -E 'CEarlyVideoService::(startEarlyHmiTimeoutTimer|onEarlyHmiTimeout|init|CEarlyVideoService)' | head
