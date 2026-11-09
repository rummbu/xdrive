#!/bin/bash
R=/srv/mgu22/root
L=$R/usr/lib/libcod.so.0.1.1
G="gdb-multiarch -q -batch -ex 'set pagination off'"
dis() { gdb-multiarch -q -batch -ex 'set pagination off' -ex "file $1" -ex "disassemble $2" 2>/dev/null | grep -vE '^(End|Dump)'; }
echo "#### cod_init"; dis $L cod_init
echo "#### cod_get_flag"; dis $L cod_get_flag
echo "#### cod_close"; dis $L cod_close | head -30
echo "#### Hmi8 callers"
H=$R/opt/ivi/rootfs/usr/bin/Hmi8
aarch64-linux-gnu-nm -D $H 2>/dev/null | grep -E 'CVACodingLibCod' | head
for s in _ZN15CVACodingLibCodC1Ev _ZN15CVACodingLibCod12getCodingValE15VACodingFeatureRh; do echo "## $s"; dis $H $s | head -120; done
