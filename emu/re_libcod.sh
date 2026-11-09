#!/bin/bash
# Dump libcod for reverse engineering (small lib) + its strings + the CAF schema header.
R=/srv/mgu22/root
L=$R/usr/lib/libcod.so.0
OUT="$(cat /srv/mgu22/repo_root)/_re"
mkdir -p "$OUT"
aarch64-linux-gnu-objdump -d -C --no-show-raw-insn $L > "$OUT/libcod.s"
aarch64-linux-gnu-objdump -s -j .rodata $L > "$OUT/libcod.rodata.txt"
aarch64-linux-gnu-readelf -dW $L | grep NEEDED
aarch64-linux-gnu-nm -D --undefined-only $L
strings -n 4 $L | grep -vE '^\.|GLIBC|^_' | head -80
echo "== schema files =="; ls -la $R/usr/share/sysfunc/coding/ | head -20
xxd $R/usr/share/sysfunc/coding/cafd_mgu_02_l.bin | head -40
echo "== ncd dir =="; ls -la $R/var/ncd 2>&1 | head
wc -l "$OUT/libcod.s"
