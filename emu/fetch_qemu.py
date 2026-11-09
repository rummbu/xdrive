#!/usr/bin/env python3
"""Fetch a newer static qemu-user from Debian (amd64) and extract it to /opt/qemu-new.
Ubuntu 24.04's qemu 8.2 crashes internally ("QEMU internal SIGSEGV") on some GPU-mode boots.
The .deb is checked against the SHA256 in the Debian Packages index before extraction.
usage: python3 -I fetch_qemu.py [suite]   (default: trixie; e.g. sid, trixie-backports)
"""
import hashlib, lzma, os, re, shutil, subprocess, sys, tempfile, urllib.request

MIRROR = 'https://deb.debian.org/debian'
DEST = '/opt/qemu-new'
CANDIDATES = ['qemu-user-static', 'qemu-user']


def main():
    suite = sys.argv[1] if len(sys.argv) > 1 else 'trixie'
    url = f'{MIRROR}/dists/{suite}/main/binary-amd64/Packages.xz'
    print('index', url, flush=True)
    txt = lzma.decompress(urllib.request.urlopen(url, timeout=120).read()).decode('utf-8', 'replace')
    pk = {}
    for block in txt.split('\n\n'):
        f = dict(re.findall(r'^([A-Za-z0-9-]+): (.*)$', block, re.M))
        if f.get('Package') in CANDIDATES:
            pk[f['Package']] = f
    for name in CANDIDATES:
        if name in pk:
            print(f"  {name} {pk[name]['Version']} size={int(pk[name]['Size'])//1024} KB")
    with tempfile.TemporaryDirectory() as td:
        for name in CANDIDATES:
            f = pk.get(name)
            if not f:
                continue
            deb = os.path.join(td, name + '.deb')
            urllib.request.urlretrieve(f'{MIRROR}/{f["Filename"]}', deb)
            h = hashlib.sha256(open(deb, 'rb').read()).hexdigest()
            if h != f['SHA256']:
                sys.exit(f'{name}: SHA256 mismatch {h} != {f["SHA256"]}')
            x = os.path.join(td, 'x')
            subprocess.run(['dpkg-deb', '-x', deb, x], check=True)
            for root, _, files in os.walk(x):
                for fn in files:
                    if fn in ('qemu-aarch64-static', 'qemu-aarch64'):
                        p = os.path.join(root, fn)
                        info = subprocess.run(['file', '-b', p], capture_output=True, text=True).stdout
                        if 'statically linked' in info or 'static-pie' in info:
                            os.makedirs(DEST, exist_ok=True)
                            out = os.path.join(DEST, 'qemu-aarch64-static')
                            shutil.copy2(p, out)
                            os.chmod(out, 0o755)
                            print(f'{name} {f["Version"]}: sha256 ok, {fn} -> {out}')
                            subprocess.run([out, '--version'])
                            return
    sys.exit('no static qemu-aarch64 found in ' + ', '.join(c for c in CANDIDATES if c in pk))


if __name__ == '__main__':
    main()
