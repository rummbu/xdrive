#!/usr/bin/env python3
"""Pull Ubuntu 22.04 (jammy, glibc 2.35 == MGU22's) arm64 Mesa + deps into an overlay dir.
Replaces the Adreno blob so the real Hmi8 can render with llvmpipe under qemu.
usage: python3 -I fetch_mesa.py <overlay-dir>
"""
import lzma, os, re, subprocess, sys, tempfile, urllib.request

MIRROR = 'http://ports.ubuntu.com/ubuntu-ports'
SUITES = ['jammy-updates', 'jammy']  # first hit wins
COMPS = ['main', 'universe']
ROOTS = ['libegl1', 'libegl-mesa0', 'libgles2', 'libgbm1', 'libgl1-mesa-dri', 'libglapi-mesa', 'libwayland-egl1']
if len(sys.argv) > 2:  # extra packages, e.g. mesa-utils-bin for es2_info/eglinfo
    ROOTS = sys.argv[2:]
# provided by the firmware (or must stay the firmware's): never overlay these
SKIP = {'libc6', 'libgcc-s1', 'gcc-12-base', 'libcrypt1', 'debconf', 'dpkg', 'perl-base', 'libselinux1', 'libpcre2-8-0'}


def index():
    pk = {}
    for suite in reversed(SUITES):  # later assignment (jammy-updates) overrides
        for c in COMPS:
            url = f'{MIRROR}/dists/{suite}/{c}/binary-arm64/Packages.xz'
            print('index', url, flush=True)
            txt = lzma.decompress(urllib.request.urlopen(url, timeout=120).read()).decode('utf-8', 'replace')
            for block in txt.split('\n\n'):
                f = dict(re.findall(r'^([A-Za-z-]+): (.*)$', block, re.M))
                if 'Package' in f:
                    pk[f['Package']] = f
                    for p in f.get('Provides', '').split(','):
                        p = p.strip().split(' ')[0]
                        if p and p not in pk:
                            pk.setdefault('virtual:' + p, f)
    return pk


def resolve(pk):
    want, todo = {}, list(ROOTS)
    while todo:
        n = todo.pop()
        if n in want or n in SKIP:
            continue
        f = pk.get(n) or pk.get('virtual:' + n)
        if not f:
            print('  ! unresolved', n); continue
        want[f['Package']] = f
        for field in ('Depends', 'Pre-Depends'):
            for alt in f.get(field, '').split(','):
                alt = alt.strip()
                if alt:
                    todo.append(alt.split('|')[0].strip().split(' ')[0].split(':')[0])
    return want


def main():
    dest = os.path.abspath(sys.argv[1]); os.makedirs(dest, exist_ok=True)
    want = resolve(index())
    print(len(want), 'packages:', ' '.join(sorted(want)), flush=True)
    with tempfile.TemporaryDirectory() as td:
        for name, f in sorted(want.items()):
            deb = os.path.join(td, name + '.deb')
            urllib.request.urlretrieve(f'{MIRROR}/{f["Filename"]}', deb)
            subprocess.run(['dpkg-deb', '-x', deb, dest], check=True)
    print('DONE', dest)


if __name__ == '__main__':
    main()
