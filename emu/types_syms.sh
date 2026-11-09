#!/bin/bash
# types_syms.sh <regex-on-libname> <regex-on-symbol> : demangled exported symbols across matching libs
R=/srv/mgu22/root
for L in $(ls $R/usr/lib/*.so* $R/opt/ivi/rootfs/usr/lib/*.so* 2>/dev/null | grep -E "$1"); do
  [ -L "$L" ] && continue
  aarch64-linux-gnu-nm -DC --defined-only "$L" 2>/dev/null | sed -E 's/^[0-9a-f]+ [A-Za-z] //' | grep -E "$2" | sed "s|^|$(basename $L): |"
done | sort -u | head -${3:-80}
