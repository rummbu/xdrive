#!/usr/bin/env python3
"""Build KombiInterface_2 check-control payloads for carsim (svc b011).
CCM list (event 8002) = array< union(len u32, type u32 = 1, CCListElementStruct{u16 ccId, string text}) >
SOME/IP string = u32 byte length | UTF-8 BOM | text | NUL
usage: ccmsg.py list "ID:text" ["ID:text" ...]   -> hex payload for 'set b011 0001 8002 <hex>'
       ccmsg.py clear                            -> empty list
"""
import struct, sys


def sstr(t, enc='utf-16be'):
    # KombiInterface_2 strings use a UTF-16 deployment (UTF-8 fails in the HMI's InputStream)
    if enc == 'utf-8':
        b = b'\xef\xbb\xbf' + t.encode('utf-8') + b'\0'
    else:
        b = b'\xfe\xff' + t.encode('utf-16be') + b'\0\0'
    return struct.pack('>I', len(b)) + b


TAIL = bytes(16)  # fields after the text (widths unconfirmed); the union length lets us over-supply


def element(cc_id, text, tail=None):
    # CCListElementStruct: u16 ccId | string text | (u16, enum, enum, u32 per the HMI's internal copy)
    el = struct.pack('>H', cc_id) + sstr(text) + (TAIL if tail is None else tail)
    return struct.pack('>II', len(el), 1) + el


def cclist(items):
    body = b''.join(element(i, t) for i, t in items)
    return struct.pack('>I', len(body)) + body


if __name__ == '__main__':
    if len(sys.argv) < 2 or sys.argv[1] == 'clear':
        print(cclist([]).hex())
    else:
        items = []
        args = sys.argv[2:]
        if args == ['-']:  # one item per stdin line (warn.ps1 uses this; wsl.exe mangles argv)
            args = [l.strip().lstrip('﻿') for l in sys.stdin if l.strip().lstrip('﻿')]
        for a in args:
            if a.startswith('hex='):  # warn.ps1 hex-encodes items so spaces survive wsl.exe
                a = bytes.fromhex(a[4:]).decode('utf-8')
            i, t = a.split(':', 1)
            items.append((int(i, 0), t))
        print(cclist(items).hex())
