#!/bin/bash
R=/srv/mgu22/root
bash /srv/mgu22/setup.sh >/dev/null
B=$R/opt/ivi/rootfs/usr/bin/Hmi8
echo "== strings: data dir / brand / begu paths"
strings -n 6 $B | grep -E '^/|hmi-data|hmi-vehicles|begu|OptionalData|data paths|hmiplugins|/ro/|brand' | grep -viE '\.(cpp|h|hpp)$|::' | sort -u | head -70
echo "== ro dir"; ls -la $R/opt/ivi/rootfs/usr/share/hmi/data/ro/
echo "== hmi-data/bmw top"; ls $R/var/begu/hmi-data/bmw $R/var/begu/hmi-data/bmw/id8 | head -30
echo "== hmi-data/bmw-shared"; ls -R $R/var/begu/hmi-data/bmw-shared | head
echo "== vehicles"; ls $R/var/begu/hmi-vehicles/g26bev
echo "== hmiplugins anywhere?"; find $R/var/begu $R/opt/ivi/rootfs/usr/share/hmi -maxdepth 4 -iname '*hmiplugin*' 2>/dev/null | head
echo "== symlinks into /var/begu in ivi"; find $R/opt/ivi/rootfs -type l -lname '/var/begu*' -printf '%p -> %l\n' 2>/dev/null | sed "s#$R##" | head -20
