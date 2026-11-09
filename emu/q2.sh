#!/bin/bash
J=/srv/mgu22/cafd_l.json
python3 -I - "$J" <<'EOF'
import json, sys
bl = json.load(open(sys.argv[1]))
a0 = [b for b in bl if b['area'] == 0][0]
fl = {f['name']: f for f in a0['flags']}
print('SERIES:', [k for k in fl['SERIES']['enums'] if k.startswith(('G08', 'G07'))])
import re
txt = open('/srv/mgu22/root/opt/ivi/rootfs/usr/share/hmi/data/ro/MGU22_Coding.txt', encoding='latin-1').read()
vals = dict(re.findall(r'^"([A-Z0-9_]+)":"([^"]*)"', txt, re.M))
missing = [n for n in fl if n not in vals]
print('schema flags without txt value:', len(missing), missing[:10])
print('txt names not in schema:', [n for n in vals if n not in fl][:10])
pat = re.compile(r'BEV|PHEV|HYBRID|ELECTR|E_DRIVE|EDRIVE|CHARG|FUEL|ENGINE|MOTOR|DRIVE_TYPE|ANTRIEB|HV_|KRAFTSTOFF|COMBUSTION|ICE_|DRIVETRAIN|GEARBOX|TRANSMISSION|XDRIVE|STEERING|COUNTRY|MARKET|REGION|LANGUAGE|UNIT', re.I)
for n in fl:
    if pat.search(n):
        e = fl[n]['enums']
        print(f"{n:<45} = {vals.get(n)!r:<28} {list(e)[:12] if e else ''}")
EOF
