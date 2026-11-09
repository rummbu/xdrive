#!/bin/bash
# Name the missing services: service.instance -> interface (from someip_map.tsv)
SRC="$(cat /srv/mgu22/repo_root)/emu"
tr -d '\r' < "$SRC/someip_gaps.sh" | bash > /dev/null
python3 -I - <<'EOF' > /srv/mgu22/someip_gaps_named.txt
names = {}
for ln in open('/srv/mgu22/someip_map.tsv'):
    s, i, ver, kind, name, lib = ln.rstrip('\n').split('\t')
    n = name.replace('local:', '').rsplit(':', 1)[0]
    names.setdefault(s, set()).add(n)
for g in open('/tmp/gaps').read().split():
    s, i = g.split('.')
    print(g, ' | '.join(sorted(names.get(s, {'?'}))))
EOF
wc -l < /srv/mgu22/someip_gaps_named.txt
grep -iE 'climat|vehicle|checkcontrol|ccm|journey|trip|kombi|cluster|speed|clock|time|temperature|fuel|tank|range|door|light|tire|tyre|oil|service|warning|message' /srv/mgu22/someip_gaps_named.txt | head -60
