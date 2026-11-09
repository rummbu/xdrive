#!/bin/bash
# capi_layouts2.sh <svc> [idprefix] : wire layout of each decoded message id (first array element,
# or the whole payload for non-array types), from capi-trace output in hmi.log
python3 -I - "$1" "${2:-}" <<'EOF'
import re, sys
svc, pre = sys.argv[1], sys.argv[2]
seqs, cur = {}, None
for l in open('/srv/mgu22/hmi.log', 'rb').read().decode('latin-1').splitlines():
    if not l.startswith('CAPI ' + svc + '.'): continue
    p = l.split(' ', 3); mid = p[1].split('.')[1]
    if p[2] == 'BEGIN': cur = mid; seqs[mid] = []; continue
    if cur == mid: seqs[mid].append(re.sub(r' -> .*', '', p[2] + (' ' + p[3] if len(p) > 3 else '')))
for mid, s in sorted(seqs.items()):
    if pre and not mid.startswith(pre): continue
    t = ' '.join(s)
    if t.startswith('len w=4') and 'len w=0' in t:
        el = t.split('len w=0')[1].strip()
        print(f'{svc}.{mid}  array<{{ {el} }}>')
    else:
        print(f'{svc}.{mid}  {t[:120]}')
EOF
