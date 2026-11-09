#!/bin/bash
R=/srv/mgu22/root
cat $R/etc/commonapi4someip-ETS.ini
echo "== any ini/json with service=0x mappings =="
grep -rlsE '^service=0x|"service" *: *"0x' $R/etc $R/opt/ivi/rootfs/etc $R/opt/ivi/rootfs/usr/share 2>/dev/null | grep -v vsomeip_security | head
echo "== climate proxy lib =="
ls $R/opt/ivi/rootfs/usr/lib/ $R/usr/lib 2>/dev/null | grep -iE 'climate|hvac|ihka' | head
P=$(ls $R/opt/ivi/rootfs/usr/lib/*limate*proxy.someip* $R/usr/lib/*limate*proxy.someip* 2>/dev/null | head -1); echo "lib: $P"
[ -n "$P" ] && strings -n 6 $P | grep -E '^local:|de\.bmw\..*:v[0-9]' | sort -u | head -10
