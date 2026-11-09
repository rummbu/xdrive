#!/bin/bash
R=/srv/mgu22/root
echo "== vsomeipd.service"; grep -vE '^\s*(#|$)' $R/etc/systemd/system/vsomeipd.service
for e in $(grep -hoE 'EnvironmentFile=-?[^ ]+' $R/etc/systemd/system/vsomeipd.service | cut -d= -f2 | tr -d -); do echo "== $e"; cat $R$e; done
echo "== /etc/vsomeip/mgu"; ls $R/etc/vsomeip/mgu | head -30
grep -lE '"routing"' -r $R/etc/vsomeip/mgu 2>/dev/null | head -3
grep -rhoE '"routing"\s*:\s*"[^"]+"' $R/etc/vsomeip 2>/dev/null | sort | uniq -c
grep -rhoE '"(unicast|base-path|network)"\s*:\s*"[^"]+"' $R/etc/vsomeip/mgu 2>/dev/null | sort | uniq -c | head
