#!/usr/bin/env python3
"""BMW CAFD coding-schema reader (as consumed by MGU22 libcod.so.0).

Format (reverse engineered from libcod cod_load_block_schema / cod_read_signed_flag):
  size-prefixed FlatBuffer, file_identifier 'CAFD'; root.f0 = [Block]
  Block: f3 u32 area id (-> /var/ncd/area_%02u.bin), f10 u32 alt id, f2 -> Version{f1 u32 id,
         f2 u8 major, f3 u8 minor}, f4 struct{u32 ?, u32 siglen}, f7 u8, f9 [Flag], f12 u8 enabled,
         f13 u32 coding data length, f14 [ubyte] extra; expected file size =
         len(f14) + f13 + siglen + 8; bytes [size-siglen-8+5], [+6] must equal major/minor.
  Flag:  f0 name, f3 struct{u32 start_byte, u32 end_byte, u8 mask}, f7 [Enum], f8 max str, f9 min str
         value = big-endian data[start..end] & mask, shifted down to the mask's lowest bit.
usage: python3 -I cafd.py cafd.bin [--json out.json] [--grep NAME]
"""
import json, struct, sys

class Caf:
    def __init__(self, path):
        self.B = open(path, 'rb').read()
        assert self.B[8:12] == b'CAFD', 'not a CAFD schema'

    def u8(self, o): return self.B[o]
    def u16(self, o): return struct.unpack_from('<H', self.B, o)[0]
    def u32(self, o): return struct.unpack_from('<I', self.B, o)[0]
    def i32(self, o): return struct.unpack_from('<i', self.B, o)[0]
    def u64(self, o): return struct.unpack_from('<Q', self.B, o)[0]

    def field(self, t, i):
        vt = t - self.i32(t)
        if 4 + 2 * i >= self.u16(vt):
            return None
        off = self.u16(vt + 4 + 2 * i)
        return t + off if off else None

    def ref(self, p): return p + self.u32(p)

    def string(self, t, i):
        p = self.field(t, i)
        if p is None: return None
        s = self.ref(p); n = self.u32(s)
        return self.B[s + 4:s + 4 + n].decode('latin-1')

    def vector(self, t, i):
        p = self.field(t, i)
        if p is None: return []
        v = self.ref(p); n = self.u32(v)
        return [v + 4 + 4 * k for k in range(n)]

    def scalar(self, t, i, kind='u32', default=0):
        p = self.field(t, i)
        if p is None: return default
        return getattr(self, kind)(p)

    def tables(self, t, i): return [self.ref(p) for p in self.vector(t, i)]

    def strings_of(self, t, maxf=24):
        out = {}
        for i in range(maxf):
            try:
                s = self.string(t, i)
                if s and all(32 <= ord(c) < 127 for c in s): out[i] = s
            except Exception:
                pass
        return out

    def blocks(self):
        root = 4 + self.u32(4)
        res = []
        for b in self.tables(root, 0):
            ver = self.ref(self.field(b, 2)) if self.field(b, 2) else None
            f4 = self.field(b, 4)
            siglen = self.u32(f4 + 4) if f4 else 0
            f14 = self.field(b, 14)
            extra = self.u32(self.ref(f14)) if f14 else 0
            datalen = self.scalar(b, 13)
            blk = dict(
                area=self.scalar(b, 3), alt=self.scalar(b, 10),
                ver_id=self.scalar(ver, 1) if ver else 0,
                major=self.scalar(ver, 2, 'u8') if ver else 0,
                minor=self.scalar(ver, 3, 'u8') if ver else 0,
                siglen=siglen, datalen=datalen, extra=extra,
                filesize=extra + datalen + siglen + 8,
                strings=self.strings_of(b), flags=[])
            for f in self.tables(b, 9):
                st = self.field(f, 3)
                fl = dict(name=self.string(f, 0), start=self.u32(st) if st else None,
                          end=self.u32(st + 4) if st else None, mask=self.u8(st + 8) if st else None,
                          max=self.string(f, 8), min=self.string(f, 9), enums={})
                for e in self.tables(f, 7):
                    names = self.strings_of(e, 8)
                    val = self.scalar(e, 1, 'u64') if self.field(e, 1) else None
                    fl['enums'][names.get(0) or str(names)] = val
                    fl.setdefault('_enum_raw', names)
                blk['flags'].append(fl)
            res.append(blk)
        return res


if __name__ == '__main__':
    c = Caf(sys.argv[1])
    bl = c.blocks()
    if '--json' in sys.argv:
        json.dump(bl, open(sys.argv[sys.argv.index('--json') + 1], 'w'), indent=1)
    g = sys.argv[sys.argv.index('--grep') + 1] if '--grep' in sys.argv else None
    for b in bl:
        print(f"area {b['area']:>3} alt {b['alt']:>3} ver {b['major']}.{b['minor']} datalen {b['datalen']} "
              f"siglen {b['siglen']} extra {b['extra']} file {b['filesize']} flags {len(b['flags'])} {b['strings']}")
        for f in b['flags']:
            if g and g.lower() in (f['name'] or '').lower():
                print('   ', f)
