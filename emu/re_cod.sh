#!/bin/bash
# Reverse-engineering pass on libcod: exports, imports by Hmi8, cod_init control flow.
R=/srv/mgu22/root
command -v aarch64-linux-gnu-objdump >/dev/null || DEBIAN_FRONTEND=noninteractive apt-get install -y -qq binutils-aarch64-linux-gnu gcc-aarch64-linux-gnu >/dev/null 2>&1
L=$R/usr/lib/libcod.so.0.1.1
OD=aarch64-linux-gnu-objdump
echo "== libcod exports"; aarch64-linux-gnu-nm -D --defined-only $L | grep ' T ' | awk '{print $3}' | tr '\n' ' '; echo
echo "== libcod imports"; aarch64-linux-gnu-nm -D --undefined-only $L | awk '{print $2}' | tr '\n' ' '; echo
echo "== cod_* used by Hmi8 and other HMI libs"
aarch64-linux-gnu-nm -D --undefined-only $R/opt/ivi/rootfs/usr/bin/Hmi8 | grep -oE 'cod_[a-z_0-9]+' | sort -u | tr '\n' ' '; echo
for f in $R/opt/ivi/rootfs/usr/lib/hmi/*.so* $R/opt/ivi/rootfs/usr/lib/*.so*; do [ -L "$f" ] && continue; s=$(aarch64-linux-gnu-nm -D --undefined-only "$f" 2>/dev/null | grep -oE 'cod_[a-z_0-9]+' | sort -u | tr '\n' ' '); [ -n "$s" ] && echo "$(basename $f): $s"; done | head -15
echo "== libcod strings (messages / paths)"
strings -n 6 $L | grep -vE '^_Z|^\.|GLIBC|^lib' | head -80
echo "== cod_init disasm"
$OD -d --no-show-raw-insn $L | awk '/<cod_init>:/,/^$/' | head -160
