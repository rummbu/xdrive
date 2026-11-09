#!/bin/bash
R=/srv/mgu22/root
echo "== who writes/reads variant.env"
grep -rlsE 'variant\.env' $R/etc $R/usr/bin $R/usr/sbin $R/usr/lib/systemd $R/lib/systemd 2>/dev/null | head
for f in $(grep -rlsE 'variant\.env' $R/etc/systemd $R/lib/systemd 2>/dev/null | head -4); do echo "-- $f"; grep -vE '^\s*(#|$)' $f | head -15; done
echo "== variant.env keys referenced in binaries"
for b in $(grep -rlsE 'variant\.env' $R/usr/bin $R/usr/sbin 2>/dev/null | head -3); do echo "-- $b"; strings -n 4 $b | grep -E '^[A-Z][A-Z0-9_]{3,}=?$|=%s|BAUREIHE|TYPE' | sort -u | head -25; done
echo "== sysfunc coding dir"; ls $R/usr/share/sysfunc/coding 2>&1 | head
echo "== BAUREIHE in variant registry & coding txt"
grep -c BAUREIHE $R/opt/ivi/rootfs/usr/share/hmi/data/ro/MGU22_Coding.txt
strings $R/var/begu/hmi-data/bmw/widget/variantregistry.pbvar 2>/dev/null | grep -m8 BAUREIHE
echo "== Hmi8 strings near -cp / coding path / json"
strings -n 5 $R/opt/ivi/rootfs/usr/bin/Hmi8 | grep -iE 'coding_jsonroot|MGU22_Coding|codingpath|coding path|\.txt.*coding|CHmiCodingJson|CodingJson|CVACodingLib|coding file' | sort -u | head -20
