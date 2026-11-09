#!/usr/bin/env python3
"""Recover CommonAPI SOME/IP member IDs from a stripped *.proxy.someip.so.

The generated proxy constructor builds every attribute/broadcast object with immediates
(getter/setter method id, notifier event id, eventgroup) and a pointer to its *Deployment object;
methods pass their method id + argument deployments to ProxyHelper calls. Deployment objects
are reached through the GOT, so dynamic relocations name them. For each call site we print the
16-bit immediates in w1..w7 and the deployment symbols held in x registers.
usage: python3 -I proxy_ids.py <lib> [filter-regex]
"""
import re, subprocess, sys

lib = sys.argv[1]
flt = re.compile(sys.argv[2]) if len(sys.argv) > 2 else None
rel = subprocess.run(['aarch64-linux-gnu-readelf', '-rW', '-C', lib], capture_output=True, text=True).stdout
got = {}
for ln in rel.splitlines():
    p = ln.split()
    if len(p) >= 5 and re.match(r'^[0-9a-f]{8,16}$', p[0]) and 'GLOB_DAT' in p[2]:
        got[int(p[0], 16)] = ' '.join(p[4:]).split(' + ')[0]
    elif len(p) >= 4 and re.match(r'^[0-9a-f]{8,16}$', p[0]) and 'RELATIVE' in p[2]:
        pass
dis = subprocess.run(['aarch64-linux-gnu-objdump', '-d', '-C', '--no-show-raw-insn', lib],
                     capture_output=True, text=True).stdout.splitlines()
ADRP = re.compile(r'\badrp\s+x(\d+),\s+([0-9a-f]+)')
LDR = re.compile(r'\bldr\s+x(\d+),\s+\[x(\d+),\s+#(\d+)\]')
ADD = re.compile(r'\badd\s+x(\d+),\s+x(\d+),\s+#0x([0-9a-f]+)')
MOVW = re.compile(r'\bmov\s+w(\d+),\s+#(0x[0-9a-f]+|-?\d+)')
MOVX = re.compile(r'\bmov\s+x(\d+),\s+x(\d+)\b')
page, xsym, wimm = {}, {}, {}
func = ''
for ln in dis:
    if re.match(r'^[0-9a-f]+ <', ln):
        func = ln.split('<', 1)[1].rstrip('>:')
        page, xsym, wimm = {}, {}, {}
        continue
    m = ADRP.search(ln)
    if m: page[int(m.group(1))] = int(m.group(2), 16); xsym.pop(int(m.group(1)), None)
    m = LDR.search(ln)
    if m and int(m.group(2)) in page:
        a = page[int(m.group(2))] + int(m.group(3))
        if a in got: xsym[int(m.group(1))] = got[a]
    m = MOVX.search(ln)
    if m and int(m.group(2)) in xsym: xsym[int(m.group(1))] = xsym[int(m.group(2))]
    m = MOVW.search(ln)
    if m: wimm[int(m.group(1))] = int(m.group(2), 0) & 0xffff
    if re.search(r'\bbl\s', ln):
        callee = ln.split('<', 1)[1].rstrip('>') if '<' in ln else ''
        deps = sorted(set(v for k, v in xsym.items() if 'Deployment' in v))
        ids = {k: v for k, v in wimm.items() if 1 <= k <= 7}
        if deps or (ids and ('SomeIP' in callee)):
            short = lambda s: re.sub(r'v\d+::de::bmw::[a-z0-9_:]+?::([A-Z][A-Za-z0-9]*_?)::', r'\1::', s)
            out = f"{' '.join(f'w{k}={v:#06x}' for k, v in sorted(ids.items()))} | {', '.join(short(d) for d in deps)} | -> {callee[:90]}"
            if not flt or flt.search(out):
                print(out)
        wimm = {}
        for r in range(0, 19): xsym.pop(r, None)
