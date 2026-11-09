#!/bin/bash
R=/srv/mgu22/root
U=$(find $R -xdev -name 'persod.service' 2>/dev/null | head -1)
echo "== $U"; cat "$U"
B=$(find $R -xdev -type f -name persod 2>/dev/null | head -1); echo "binary: $B"
aarch64-linux-gnu-readelf -d $B | grep NEEDED | wc -l
strings -n 6 $B | grep -E '^/(etc|var|opt|run)/' | sort -u | head -20
echo "== what the HMI says about personalization =="
grep -aiE 'personaliz|persod|DevCarPersonalization|UserAccount' /srv/mgu22/hmi.log | cut -c95-260 | sort | uniq -c | sort -rn | head -10
