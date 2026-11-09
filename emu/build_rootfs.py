#!/usr/bin/env python3
"""Rebuild the MGU22 (iDrive 8.5) filesystem from the dump zip into a runnable aarch64 rootfs.

Layout (from the firmware's own container-ivi.service / ld.so.conf.d):
    /                  <- ROOT_rootfs   (metadata partition 9ff7)
    /opt/ivi/rootfs    <- ivi_fs/rootfs (metadata partition 9fc6)  Hmi8 lives here
    /opt/ext/rootfs    <- ext_fs/rootfs (metadata partition 9ff9)
SWFK HMI data images are copied to <dest>/../swfk for loop mounting.

usage: python3 -I build_rootfs.py <dump.zip> <dest-root>
"""
import json, os, stat, sys, zipfile, shutil

PARTS = {  # inner zip -> (strip prefix, dest subdir, metadata partition id)
    'ROOT_rootfs.zip': ('ROOT_rootfs/', '', '9ff7'),
    'ivi_fs.zip': ('ivi_fs/rootfs/', 'opt/ivi/rootfs', '9fc6'),
    'ext_fs.zip': ('ext_fs/rootfs/', 'opt/ext/rootfs', '9ff9'),
}
PFX = 'bmw mgu22 filesystem/'


def safe_join(base, rel):
    p = os.path.normpath(os.path.join(base, rel))
    if not (p == base or p.startswith(base + os.sep)):
        raise ValueError('path escapes root: ' + rel)
    return p


def extract(inner, strip, dest):
    n = 0
    for i in inner.infolist():
        name = i.filename
        if '__MACOSX' in name or name.endswith('.DS_Store') or not name.startswith(strip):
            continue
        rel = name[len(strip):]
        if not rel:
            continue
        out = safe_join(dest, rel)
        mode = (i.external_attr >> 16) & 0xFFFF
        if name.endswith('/'):
            os.makedirs(out, exist_ok=True)
            continue
        os.makedirs(os.path.dirname(out), exist_ok=True)
        if os.path.islink(out) or os.path.exists(out):
            os.remove(out)
        if stat.S_ISLNK(mode):
            os.symlink(inner.read(i).decode(), out)
        else:
            with inner.open(i) as src, open(out, 'wb') as dst:
                shutil.copyfileobj(src, dst, 1 << 20)
            if mode & 0o777:
                os.chmod(out, mode & 0o7777)
        n += 1
    return n


def apply_meta(tree, dest):
    links = modes = 0
    for rel, e in tree.items():
        p = safe_join(dest, rel.lstrip('/'))
        if 'link' in e:
            os.makedirs(os.path.dirname(p), exist_ok=True)
            if os.path.lexists(p):
                if os.path.isdir(p) and not os.path.islink(p):
                    shutil.rmtree(p)
                else:
                    os.remove(p)
            os.symlink(e['link'], p)
            links += 1
        elif 'mode' in e and os.path.lexists(p) and not os.path.islink(p):
            os.chmod(p, e['mode'] & 0o7777)
            modes += 1
    return links, modes


def main():
    src, root = sys.argv[1], os.path.abspath(sys.argv[2])
    os.makedirs(root, exist_ok=True)
    outer = zipfile.ZipFile(src)
    meta = json.load(outer.open(PFX + 'emulator-filesystem-metadata.json'))['partitions']
    for zn, (strip, sub, pid) in PARTS.items():
        dest = os.path.join(root, sub) if sub else root
        print(f'[{zn}] extracting -> {dest}', flush=True)
        n = extract(zipfile.ZipFile(outer.open(PFX + zn)), strip, dest)
        l, m = apply_meta(meta[pid], dest)
        print(f'[{zn}] files={n} symlinks={l} modes={m}', flush=True)
    swfk = os.path.join(os.path.dirname(root), 'swfk')
    os.makedirs(swfk, exist_ok=True)
    for i in outer.infolist():
        if i.filename.endswith('.ext4') and '/swfk_' in i.filename:
            out = os.path.join(swfk, os.path.basename(i.filename))
            if not os.path.exists(out) or os.path.getsize(out) != i.file_size:
                print('[swfk]', os.path.basename(out), i.file_size, flush=True)
                with outer.open(i) as s, open(out, 'wb') as d:
                    shutil.copyfileobj(s, d, 1 << 20)
    print('DONE', flush=True)


if __name__ == '__main__':
    main()
