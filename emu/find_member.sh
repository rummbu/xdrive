#!/bin/bash
# find_member.sh <regex> : which *.someip.so libs export a deployment/member matching regex
R=/srv/mgu22/root
for L in $R/usr/lib/*.someip.so* $R/opt/ivi/rootfs/usr/lib/*.someip.so*; do
  [ -L "$L" ] && continue
  aarch64-linux-gnu-nm -DC --defined-only "$L" 2>/dev/null | grep -qiE "$1" && echo "$(basename $L): $(aarch64-linux-gnu-nm -DC --defined-only "$L" | grep -iE "$1" | head -2 | sed -E 's/^[0-9a-f]+ . //' | tr '\n' ' ' | cut -c1-200)"
done | head -${2:-15}
