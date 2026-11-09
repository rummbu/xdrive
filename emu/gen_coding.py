#!/usr/bin/env python3
"""Generate MGU22 NCD coding data (/var/ncd/area_NN.bin) that libcod accepts as real coding.

Values come from a readable coding template (the HMI's own ro/MGU22_Coding.txt: "NAME":"value"
lines, a G70 i7 coded for CAF 0.144) plus per-profile overrides (emu/coding/<profile>.txt, same
syntax or NAME=value). Every flag is encoded at its CAFD schema position (start/end byte, mask).
File = coding bytes + 8-byte header (byte 5/6 = block CAF major/minor, checked by cod_init) +
signature (zeros; cod_init does not verify it).

usage: python3 -I gen_coding.py <cafd.bin> <template.txt> <override.txt|-> <out_dir>
"""
import os, re, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from cafd import Caf

LINE = re.compile(r'^\s*"?([A-Z0-9_]+)"?\s*[:=]\s*"?([^"#,\s][^"#,]*?)"?\s*,?\s*(?:#.*)?$')


def read_values(path):
    vals = {}
    if path == '-' or not os.path.exists(path):
        return vals
    for ln in open(path, encoding='latin-1'):
        if ln.lstrip().startswith('#'):
            continue
        m = LINE.match(ln.rstrip('\n'))
        if m:
            vals[m.group(1)] = m.group(2).strip()
    return vals


ALL_ENUMS = {}  # name -> enums, from any area (area 2's IS_CODED has none of its own)


def encode(flag, text):
    en = flag['enums'] or ALL_ENUMS.get(flag['name'], {})
    if text in en:
        return en[text] or 0
    try:  # numeric flags sometimes carry one placeholder label ('initvalue', '_300_300')
        return int(text, 0)
    except ValueError:
        raise ValueError(f"{flag['name']}: '{text}' not one of {list(en)[:20]}")


def put(buf, flag, value):
    s, e, mask = flag['start'], flag['end'], flag['mask']
    n = e - s + 1
    if mask == 0xff:
        buf[s:e + 1] = (value & ((1 << (8 * n)) - 1)).to_bytes(n, 'big')
    else:  # sub-byte field inside the last byte of the range
        shift = (mask & -mask).bit_length() - 1
        cur = int.from_bytes(buf[s:e + 1], 'big')
        cur = (cur & ~mask) | ((value << shift) & mask)
        buf[s:e + 1] = cur.to_bytes(n, 'big')


def main(cafd, template, override, out):
    caf = Caf(cafd)
    tv, ov = read_values(template), read_values(override)
    vals = {**tv, **ov}
    os.makedirs(out, exist_ok=True)
    for blk in caf.blocks():
        for f in blk['flags']:
            if f['enums']: ALL_ENUMS.setdefault(f['name'], f['enums'])
    for blk in caf.blocks():
        names = {f['name'] for f in blk['flags']}
        # only areas the template really describes; a mostly-zero coding of another ECU area
        # (ioc/dac) would be worse than leaving it on defaults
        if len(names & set(tv)) * 2 < len(names):
            path = os.path.join(out, f"area_{blk['area']:02d}.bin")
            if os.path.exists(path): os.remove(path)
            continue
        data = bytearray(blk['datalen'] + blk['extra'])
        done, bad = 0, []
        for f in blk['flags']:
            if f['name'] not in vals:
                continue
            try:
                put(data, f, encode(f, vals[f['name']])); done += 1
            except Exception as ex:
                bad.append(str(ex))
        hdr = bytearray(8); hdr[5], hdr[6] = blk['major'], blk['minor']
        blob = bytes(data) + bytes(hdr) + bytes(blk['siglen'])
        assert len(blob) == blk['filesize'], (len(blob), blk['filesize'])
        path = os.path.join(out, f"area_{blk['area']:02d}.bin")
        open(path, 'wb').write(blob)
        print(f"area {blk['area']:02d} ({blk['strings'].get(11)}): {done}/{len(blk['flags'])} flags coded, "
              f"{len(blob)} bytes -> {path}")
        for b in bad[:10]:
            print('   !', b)
    unknown = [k for k in ov if not any(k == f['name'] for b in caf.blocks() for f in b['flags'])]
    if unknown:
        print('   ! override names not in schema:', unknown)


if __name__ == '__main__':
    main(*sys.argv[1:5])
