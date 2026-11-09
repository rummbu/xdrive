#!/bin/bash
R=/srv/mgu22/root
for f in $R/etc/systemd/system/rvp.service $R/lib/systemd/system/rvp.service; do [ -f $f ] && { echo "== $f"; grep -vE '^\s*(#|$)' $f; }; done
X=$(grep -hoE 'ExecStart=[^ ]+' $R/etc/systemd/system/rvp.service 2>/dev/null | head -1 | cut -d= -f2 | sed 's/^[-+!@]*//')
echo "== exec: $X"; file -L $R$X 2>/dev/null
if file -L $R$X | grep -q text; then cat $R$X | head -80; else strings -n 4 $R$X | grep -E '=|variant|BAUREIHE|VARIANT|BRAND|TYPE' | sort -u | head -60; fi
echo "== other readers: HMI-side keys from variant.env (Hmi8 getenv candidates)"
strings -n 6 $R/opt/ivi/rootfs/usr/bin/Hmi8 | grep -E '^(VEHICLE|VARIANT|BRAND|BAUREIHE|HW_|HMI_|MGU_|PLATFORM|CAR_|SERIES|DISPLAY)[A-Z0-9_]*$' | sort -u | head -40
