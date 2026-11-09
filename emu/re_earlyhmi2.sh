#!/bin/bash
H=/srv/mgu22/root/opt/ivi/rootfs/usr/bin/Hmi8
aarch64-linux-gnu-nm -DC $H | grep sm_cuiEarlyHmiTimeOut
A=$(aarch64-linux-gnu-nm -D $H | grep sm_cuiEarlyHmiTimeOut | awk '{print $1}')
[ -n "$A" ] && { echo "value at 0x$A:"; xxd -s 0x$A -l 4 $H; }
echo "== startEarlyHmiTimeoutTimer =="
aarch64-linux-gnu-objdump -d -C --no-show-raw-insn --start-address=0x5cc480c --stop-address=0x5cc4a00 $H | grep -E 'mov|ldr|bl\s|adrp|add\s' | head -45
