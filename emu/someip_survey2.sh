#!/bin/bash
R=/srv/mgu22/root
D=$R/etc/vsomeip/mgu
ls -la $D | head -40
echo "== how vsomeipd / HMI find their config =="
grep -rsE 'VSOMEIP_CONFIGURATION|vsomeip' $R/etc/systemd/system/vsomeipd.service $R/lib/systemd/system/vsomeipd.service $R/opt/ivi/rootfs/etc/systemd/system/hmi.service 2>/dev/null | head
find $R/etc $R/opt/ivi/rootfs/etc -maxdepth 2 -name '*.json' 2>/dev/null | grep -i someip | head
cat $R/etc/vsomeip.json 2>/dev/null | head -50
