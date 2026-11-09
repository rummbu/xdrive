#!/usr/bin/env python3
"""Generic FlatBuffers table prober for BMW CAFD coding schemas (size-prefixed, id 'CAFD').
Prints the raw fields of the root, the first blocks and their first flags so field meanings
can be identified. usage: python3 -I caf_probe.py cafd_xxx.bin
"""
import struct, sys

B = open(sys.argv[1], 'rb').read()
BASE = 4  # size prefix


def u8(o): return B[o]
def u16(o): return struct.unpack_from('<H', B, o)[0]
def u32(o): return struct.unpack_from('<I', B, o)[0]
def i32(o): return struct.unpack_from('<i', B, o)[0]


def fields(t):
    vt = t - i32(t)
    n = (u16(vt) - 4) // 2
    return {i: u16(vt + 4 + 2 * i) for i in range(n) if u16(vt + 4 + 2 * i)}


def deref(p):  # uoffset at p -> target
    return p + u32(p)


def as_string(p):
    try:
        s = deref(p); n = u32(s)
        if 0 < n < 300 and s + 4 + n <= len(B):
            raw = B[s + 4:s + 4 + n]
            if all(32 <= c < 127 for c in raw):
                return raw.decode()
    except Exception:
        pass
    return None


def vec(p):
    v = deref(p); return v + 4, u32(v)


def show(t, label, depth=0):
    ind = '  ' * depth
    print(f'{ind}{label} @{t:#x}')
    for i, off in fields(t).items():
        p = t + off
        s = as_string(p)
        try:
            vs, vn = vec(p)
        except Exception:
            vn = -1
        print(f'{ind}  f{i:<2} +{off:<3} u8={u8(p):<4} u32={u32(p):<10} str={s!r:<30} veclen={vn if 0 <= vn < 100000 else "-"}')


root = BASE + u32(BASE)
show(root, 'ROOT')
rf = fields(root)
bs, bn = vec(root + rf[0])
print('blocks:', bn)
for bi in range(min(bn, 3)):
    blk = deref(bs + 4 * bi)
    show(blk, f'BLOCK {bi}', 1)
    bf = fields(blk)
    if 2 in bf:
        show(deref(blk + bf[2]), 'block.f2 (version table)', 2)
    if 9 in bf:
        fs, fn = vec(blk + bf[9])
        print('    flags:', fn)
        for fi in range(min(fn, 2)):
            fl = deref(fs + 4 * fi)
            show(fl, f'FLAG {fi}', 2)
            ff = fields(fl)
            if 3 in ff:
                p = fl + ff[3]
                print('      f3 struct start/end/mask:', u32(p), u32(p + 4), hex(u8(p + 8)))
            for k in (7, 8, 9):
                if k in ff:
                    try:
                        es, en = vec(fl + ff[k])
                        print(f'      f{k} vector len {en}')
                        for ei in range(min(en, 4)):
                            show(deref(es + 4 * ei), f'f{k}[{ei}]', 4)
                    except Exception as e:
                        print('      f', k, 'not a vector', e)
