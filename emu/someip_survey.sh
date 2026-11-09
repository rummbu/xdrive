#!/bin/bash
R=/srv/mgu22/root
echo "== vsomeipd log: requested services (unique) =="
grep -aoE 'REQUEST\([0-9a-f]+\): \[[0-9a-f]{4}\.[0-9a-f]{4}:[0-9]+\.[0-9]+\]' /srv/mgu22/vsomeipd.log | sed 's/REQUEST([0-9a-f]*): //' | sort | uniq -c | sort -rn | head -10
grep -acE 'REQUEST' /srv/mgu22/vsomeipd.log
grep -aoE 'OFFER\([0-9a-f]+\): \[[0-9a-f]{4}\.[0-9a-f]{4}' /srv/mgu22/vsomeipd.log | sort -u | head
tail -5 /srv/mgu22/vsomeipd.log | cut -c1-200
echo "== commonapi someip config =="
ls -la $R/etc/commonapi* $R/opt/ivi/rootfs/etc/commonapi* 2>/dev/null
for f in $R/etc/commonapi-someip.ini $R/opt/ivi/rootfs/etc/commonapi-someip.ini; do [ -f $f ] && { echo "-- $f"; head -40 $f; grep -c . $f; }; done
echo "== vsomeip json configs =="
ls $R/etc/vsomeip* $R/opt/ivi/rootfs/etc/vsomeip* 2>/dev/null | head; ls $R/etc/vsomeip/ 2>/dev/null | head -30
