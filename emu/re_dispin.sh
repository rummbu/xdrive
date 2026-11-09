#!/bin/bash
# Find and disassemble CHmiDisplayAndEarlyVideoInputHandler touch path
R=/srv/mgu22/root
F=$(grep -rlas 'CHmiDisplayAndEarlyVideoInputHandler' $R/opt/ivi/rootfs/usr/lib/hmi $R/opt/ivi/rootfs/usr/bin/Hmi8 | head -5)
echo "files: $F"
for f in $F; do
  echo "== $f"
  strings -n 5 "$f" | grep -iE 'DisplayAndEarlyVideo|display (on|off)|Turning display|screen enabler|SYSTEM_DISPLAY|DISPLAY_STATE|swallow|consum|blocked|ignore.*touch|touch.*ignor' | sort -u | head -40
  aarch64-linux-gnu-nm -DC "$f" 2>/dev/null | grep -i DisplayAndEarlyVideo | head -20
done
