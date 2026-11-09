#!/bin/bash
R=/srv/mgu22/root
echo "== config files mentioning long press =="
grep -rlisE 'long_?press' $R/opt/ivi/rootfs/etc $R/etc $R/opt/ivi/rootfs/usr/share/hmi/data/ro/*.ini $R/opt/ivi/rootfs/usr/share/hmi/data/ro/*.json $R/opt/ivi/rootfs/usr/share/hmi/data/ro/*.cfg 2>/dev/null | head
ls $R/opt/ivi/rootfs/usr/share/hmi/data/ro/ | head -40
echo "== Hmi8 strings =="
strings -n 6 $R/opt/ivi/rootfs/usr/bin/Hmi8 | grep -iE 'long.?press.*(time|ms|delay|thresh|duration)|(time|delay|thresh|duration).*long.?press|GESTURE_.*(TIME|DELAY)|SYSTEM_.*(TOUCH|GESTURE)' | sort -u | head -30
echo "== project.ini gesture keys =="
grep -rihE 'long|gesture|touch' $R/opt/ivi/rootfs/usr/share/hmi/data/ro/project*.ini 2>/dev/null | head -20
find $R/opt/ivi/rootfs/usr/share/hmi -maxdepth 3 -iname '*gesture*' | head
