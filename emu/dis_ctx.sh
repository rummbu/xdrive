#!/bin/bash
# dis_ctx.sh <lib> <pattern> [before] [after] [nth]  - disassembly context around a call
L=$1; P=$2; B=${3:-30}; A=${4:-3}; K=${5:-1}
aarch64-linux-gnu-objdump -d -C --no-show-raw-insn "$L" > /tmp/dis.s
grep -n "$P" /tmp/dis.s | head -5
N=$(grep -n "$P" /tmp/dis.s | sed -n "${K}p" | cut -d: -f1)
[ -n "$N" ] && sed -n "$((N-B)),$((N+A))p" /tmp/dis.s | cut -c1-140
