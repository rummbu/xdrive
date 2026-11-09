#!/usr/bin/env python3
"""Build SOME/IP service-id -> CommonAPI interface map from the firmware's generated
*.someip.so libraries. Each one calls AddressTranslator::insert(address, service, instance,
major, minor) with x1 = address string (adrp+add) and w2..w5 immediates; we resolve all of it
from the disassembly (rodata vaddr == file offset in these libs).
usage: python3 -I someip_map.py <rootfs> <out.tsv>
"""
import glob, os, re, subprocess, sys

root, out = sys.argv[1], sys.argv[2]
libs = sorted(set(glob.glob(f'{root}/usr/lib/*.someip.so*') + glob.glob(f'{root}/opt/ivi/rootfs/usr/lib/*.someip.so*')
                  + glob.glob(f'{root}/opt/ext/rootfs/usr/lib/*.someip.so*')))
libs = [l for l in libs if not os.path.islink(l)]
MOVW = re.compile(r'\bmov\s+w([1-5]),\s+#(0x[0-9a-f]+|\d+)')
ADRP = re.compile(r'\badrp\s+x(\d+),\s+([0-9a-f]+)\b')
ADD = re.compile(r'\badd\s+x(\d+),\s+x(\d+),\s+#0x([0-9a-f]+)')
rows = set()
for lib in libs:
    data = open(lib, 'rb').read()
    if b'AddressTranslator' not in data:
        continue
    try:
        dis = subprocess.run(['aarch64-linux-gnu-objdump', '-d', '--no-show-raw-insn', lib],
                             capture_output=True, text=True, timeout=300).stdout.splitlines()
    except Exception:
        continue
    # The address std::string is built with _M_create (length in x3) and its bytes copied from a
    # rodata constant (adrp+add); remember the most recent such pointer whose bytes start 'local:'.
    w, x, src, slen = {}, {}, None, None
    MOVX3 = re.compile(r'\bmov\s+x3,\s+#(0x[0-9a-f]+|\d+)')
    for ln in dis:
        if re.match(r'^[0-9a-f]+ <', ln):
            w, x, src, slen = {}, {}, None, None
            continue
        m = MOVW.search(ln)
        if m:
            w[int(m.group(1))] = int(m.group(2), 0) & 0xffff
        m = MOVX3.search(ln)
        if m:
            slen = int(m.group(1), 0)
        m = ADRP.search(ln)
        if m:
            x[int(m.group(1))] = int(m.group(2), 16)
        m = ADD.search(ln)
        if m and int(m.group(2)) in x:
            a = x[int(m.group(2))] + int(m.group(3), 16)
            x[int(m.group(1))] = a
            if 0 < a < len(data) and data[a:a + 6] == b'local:':
                src = a
        if re.search(r'\bbl\s', ln) and 'AddressTranslator' in ln and 'insert' in ln and 2 in w:
            name = '?'
            if src is not None:
                end = src + slen if slen and slen < 300 else data.find(b'\0', src)
                s = data[src:end]
                name = s.split(b'\0')[0].decode('latin-1')
            kind = 'stub' if '.stub.' in lib else 'proxy'
            rows.add((w[2], w.get(3, 0), w.get(4, 0), w.get(5, 0), kind, name, os.path.basename(lib)))
            w, src, slen = {}, None, None
with open(out, 'w') as f:
    for r in sorted(rows):
        f.write('%04x\t%04x\t%d.%d\t%s\t%s\t%s\n' % r)
print(len(libs), 'libs,', len(rows), 'mappings ->', out)
