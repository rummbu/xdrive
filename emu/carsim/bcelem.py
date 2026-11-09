#!/usr/bin/env python3
"""Build ResetLogic3 BCDataAll3 payloads (event b04e.8007) for carsim.
BCDataAll3 = 8 bytes (6 enums + 2 u8) | 4 x u16 | array<Element> (u32 byte length)
Element (58 bytes) = type:u8 | ts:6 x u8 | a:u16 b:u8 c:u8 d:u8 e:u16 f:u32 g:u16 h:u16 i:u32 j:u32
                     k:u16 l:u16 m:u32 n:u32 o:u32 p:u32 q:u32 r:u32
usage: bcelem.py [type=val,...]  -> prints the hex payload
"""
import struct, sys

FIELDS = [('a', 'H'), ('b', 'B'), ('c', 'B'), ('d', 'B'), ('e', 'H'), ('f', 'I'), ('g', 'H'), ('h', 'H'),
          ('i', 'I'), ('j', 'I'), ('k', 'H'), ('l', 'H'), ('m', 'I'), ('n', 'I'), ('o', 'I'), ('p', 'I'),
          ('q', 'I'), ('r', 'I')]


def element(etype, ts=(8, 11, 26, 14, 30, 0), **v):
    out = struct.pack('>B6B', etype, *ts)
    for name, fmt in FIELDS:
        out += struct.pack('>' + fmt, v.get(name, 0))
    assert len(out) == 58
    return out


def bcdata(elements, head=bytes(8), u16s=(0, 0, 0, 0)):
    body = b''.join(elements)
    return head + struct.pack('>4H', *u16s) + struct.pack('>I', len(body)) + body


def m3_trip():
    """Plausible S58 M3 Competition numbers. Known fields (from on-screen probing):
    a/b/c/d = driving time days/h/min/s, l = avg consumption x10 (l/100km),
    p, q = distances x10 (km), ts = (year-2000, month, day, hour, min, s); header 01*8 = valid."""
    common = dict(l=114, a=0, b=1, c=24, d=10)
    els = [element(0, ts=(26, 11, 8, 9, 15, 0), p=124, q=864, **common),
           element(1, ts=(26, 10, 1, 8, 0, 0), p=1873, q=9120, a=1, b=6, c=40, l=118),
           element(2, ts=(24, 3, 14, 12, 0, 0), p=40210, q=150000, a=14, b=3, c=12, l=121)]
    return bcdata(els, head=bytes.fromhex('0101010101010101'))


if __name__ == '__main__':
    if len(sys.argv) > 1 and sys.argv[1] == 'm3':
        print(m3_trip().hex()); sys.exit()
    probe = {n: (i + 1) * 100 for i, (n, _) in enumerate(FIELDS)}
    probe['b'], probe['c'], probe['d'] = 1, 2, 3
    els = [element(t, **probe) for t in range(int(sys.argv[1]) if len(sys.argv) > 1 else 3)]
    head = bytes.fromhex(sys.argv[2]) if len(sys.argv) > 2 else bytes(8)
    print(bcdata(els, head=head).hex())
