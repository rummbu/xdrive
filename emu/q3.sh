#!/bin/bash
tr -d '\r' < "$(cat /srv/mgu22/repo_root)/emu/caf_q.sh" > /tmp/caf_q.sh
python3 -I - <<'EOF'
import json, re
bl = json.load(open('/srv/mgu22/cafd_l.json'))
a0 = [b for b in bl if b['area'] == 0][0]
txt = open('/srv/mgu22/root/opt/ivi/rootfs/usr/share/hmi/data/ro/MGU22_Coding.txt', encoding='latin-1').read()
vals = dict(re.findall(r'^"([A-Z0-9_]+)":"([^"]*)"', txt, re.M))
for f in a0['flags']:
    if re.search(r'COLOU?R|OFFROAD|XOFF|TWO_TONE|PAINT|INTERIOR', f['name']):
        e = list(f['enums'])
        print(f"{f['name']:<40} = {vals.get(f['name'])!r:<22} n={len(e)} {e[:60]}")
EOF
