#!/bin/bash
R=/srv/mgu22/root
bash /srv/mgu22/setup.sh >/dev/null
export QEMU_CPU=cortex-a76
mkdir -p $R/run/etc $R/run/variant $R/var/run/etc
echo "== rvp --help"; chroot $R /usr/bin/rvp --help 2>&1 | head -30
echo "== rvp configs"; grep -rlsE 'HWVAR|ECU=' $R/etc $R/usr/share 2>/dev/null | head
ls $R/etc/rvp* $R/usr/share/rvp* 2>/dev/null | head
echo "== rvp_get_ecu_type disasm (strings it compares)"
gdb-multiarch -q -batch -ex "file $R/usr/lib/libcod.so.0.1.1" -ex 'disassemble rvp_get_ecu_type' 2>/dev/null | grep -E 'bl|adrp|add.*#0x' | head -40
strings -n 3 -t x $R/usr/lib/libcod.so.0.1.1 | awk '$1 ~ /^3d|^3e|^3c/' | head -40
