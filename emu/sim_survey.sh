#!/bin/bash
R=/srv/mgu22/root
H=$R/opt/ivi/rootfs/usr/bin/Hmi8
echo "== Hmi8: simulation / mock / fake strings =="
strings -n 6 $H | grep -iE '(^|[^a-z])(simulat|mock|fake|stub mode|dummy|replay|testautomation|HMI_SIM|SIMULATION)' | grep -viE 'cpp$|^_Z|Weak_result|TCallable' | sort -u | head -50
echo "== env vars the HMI reads (getenv-ish uppercase strings) =="
strings -n 6 $H | grep -E '^[A-Z][A-Z0-9_]{5,}$' | grep -iE 'SIM|MOCK|FAKE|TEST|DEV|DEBUG|ENABLE|HMI_' | sort -u | head -60
echo "== applet / plugin libs with sim/mock in name =="
find $R/opt/ivi/rootfs/usr/lib/hmi $R/opt/ivi/rootfs/usr/lib -maxdepth 3 -iname '*sim*' -o -maxdepth 3 -iname '*mock*' -o -maxdepth 3 -iname '*fake*' 2>/dev/null | head -20
echo "== ro data: simulation configs =="
find $R/opt/ivi/rootfs/usr/share/hmi -maxdepth 4 -iname '*sim*' 2>/dev/null | head -20
