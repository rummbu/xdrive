#!/bin/bash
R=/srv/mgu22/root
find $R/var $R/run $R/tmp $R/opt/ivi/rootfs/var /srv/mgu22/root/persistence /srv/mgu22/root/data 2>/dev/null -type f -newer /srv/mgu22/root/opt/ivi/rootfs/usr/bin/Hmi8.orig ! -name '*.log' 2>/dev/null \
  | grep -vE '/proc/|/sys/' | xargs -r ls -la 2>/dev/null | sort -k5 -rn | head -25
echo "== files mentioning shader cache hash =="
grep -rlsa '6fae4e4d10ca257a' $R/var $R/run $R/opt/ivi/rootfs/var 2>/dev/null | head
grep -aE 'RamsesBinaryShaderCache' /srv/mgu22/hmi.log | grep -avE 'store:' | cut -c95-300 | sort -u | head
