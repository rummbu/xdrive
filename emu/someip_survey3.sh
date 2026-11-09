#!/bin/bash
D=/srv/mgu22/root/etc/vsomeip/mgu
ls $D/0_0 | head; du -sh $D
echo "== which uid owns HMI (hmi.service User=) and climate-ish things =="
grep -rhsE '^User=|^Group=' /srv/mgu22/root/opt/ivi/rootfs/etc/systemd/system/hmi.service
grep -E 'hmi|cos_hmi' /srv/mgu22/root/etc/passwd | head -3
echo "== sample json (first 60 lines of biggest) =="
F=$(ls -S $D/*/*.json | head -1); echo $F; head -c 2500 $F
echo; echo "== does any config carry service names? =="
grep -rlE '"name"|Climate|climate' $D | head -5
