#!/bin/bash
# capi_layouts.sh <svc> : element layout per method from the last capi-trace decode of each
python3 -I - "$1" <<'EOF'
import re, sys
svc = sys.argv[1]
lines = [l.rstrip() for l in open('/srv/mgu22/hmi.log', 'rb').read().decode('latin-1').splitlines() if l.startswith('CAPI ' + svc)]
cur, dec = None, {}
for l in lines:
    p = l.split(' ', 3)
    m, what = p[1].split('.')[1], p[2] + (' ' + p[3] if len(p) > 3 else '')
    if what.startswith('BEGIN'):
        cur = m; dec[m] = []
        continue
    if cur == m:
        dec[m].append(re.sub(r' -> .*', '', what))
for m, seq in sorted(dec.items()):
    # first element = reads between the 1st and 2nd 'len w=0' (or after the array length)
    s = ' '.join(seq)
    els = s.split('len w=0')
    first = els[1].strip() if len(els) > 1 else s
    print(f"{svc}.{m}: array[{seq[0] if seq else '?'}] elem = {{ {first} }}")
EOF
echo "== member deployments (named struct fields) =="
L=$(ls /srv/mgu22/root/usr/lib/libde.bmw.infotainment.climate.climatemaster.proxy.someip.so* | tail -1)
aarch64-linux-gnu-nm -DC $L | grep -oE 'ClimateMasterTypes_::[A-Za-z0-9_]+Deployment' | sed 's/ClimateMasterTypes_:://' | sort -u | grep -E 'Available|RequestClimateSystemOn' | head -50
