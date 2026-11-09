#!/bin/bash
# q4.sh REGEX : flag names in schema + template values
python3 -I - "$1" <<'EOF'
import json, re, sys
rx = re.compile(sys.argv[1], re.I)
bl = json.load(open('/srv/mgu22/cafd_l.json'))
txt = open('/srv/mgu22/root/opt/ivi/rootfs/usr/share/hmi/data/ro/MGU22_Coding.txt', encoding='latin-1').read()
vals = dict(re.findall(r'^"([A-Z0-9_]+)":"([^"]*)"', txt, re.M))
for b in bl:
    for f in b['flags']:
        if rx.search(f['name'] or ''):
            print(f"a{b['area']} {f['name']:<42} = {vals.get(f['name'])!r:<20} {list(f['enums'])[:8]}")
EOF
