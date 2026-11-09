#!/usr/bin/env python3
"""Search decoded CAFD flags (cafd_l.json from cafd.py). usage: caf_flags.py json REGEX [area]"""
import json, re, sys
bl = json.load(open(sys.argv[1]))
rx = re.compile(sys.argv[2], re.I)
area = int(sys.argv[3]) if len(sys.argv) > 3 else None
for b in bl:
    if area is not None and b['area'] != area: continue
    for f in b['flags']:
        if f['name'] and rx.search(f['name']):
            en = {k: (v or 0) for k, v in f['enums'].items()}
            if len(en) > 40:
                en = dict(list(en.items())[:40]); en['...'] = f'{len(f["enums"])} total'
            print(f"a{b['area']} {f['name']:<45} bytes {f['start']}-{f['end']} mask {f['mask']:#04x} {en}")
