#!/bin/bash
# First-contact probe: binfmt, SWFK mount targets, GPU libs, and Hmi8's unresolved libraries.
R=/srv/mgu22/root
update-binfmts --enable qemu-aarch64 2>/dev/null
grep -E '^(enabled|interpreter|flags)' /proc/sys/fs/binfmt_misc/qemu-aarch64 2>/dev/null

echo "== links pointing at SWFK / hmi data"
find $R/opt/ivi/rootfs/usr/share/hmi $R/opt/ivi/rootfs/usr/lib/hmi -maxdepth 4 -type l -printf '%p -> %l\n' 2>/dev/null | head -20
grep -rhoE '/var/opt/SWFK[^" ]*|hmi-data[^" ]*' $R/etc $R/opt/ivi/rootfs/etc 2>/dev/null | sort -u | head -20
ls $R/opt/ivi/rootfs/usr/share/hmi/data/ 2>/dev/null | head

echo "== target GPU / EGL libs"
ls $R/usr/lib $R/opt/ivi/rootfs/usr/lib $R/opt/ext/rootfs/usr/lib 2>/dev/null | grep -iE '^lib(EGL|GLES|gbm|wayland|adreno|gsl|mali|drm)' | sort -u
echo "== glibc"
ls $R/lib/libc.so.6 $R/usr/lib/libc.so.6 2>/dev/null; strings $R/lib/libc.so.6 2>/dev/null | grep -m1 'GNU C Library'

echo "== Hmi8 unresolved libs (ld.so --list inside chroot)"
cp /usr/bin/qemu-aarch64-static $R/usr/bin/ 2>/dev/null
export LD_LIBRARY_PATH=/opt/ivi/rootfs/usr/lib/hmi:/opt/ivi/rootfs/usr/lib:/opt/ivi/rootfs/lib:/opt/ext/rootfs/usr/lib:/opt/ext/rootfs/lib
chroot $R /lib/ld-linux-aarch64.so.1 --list /opt/ivi/rootfs/usr/bin/Hmi8 2>&1 | grep -E 'not found|error' | sort -u | head -40
echo "== ramses lib deps"
chroot $R /lib/ld-linux-aarch64.so.1 --list /opt/ivi/rootfs/usr/lib/libramses-shared-lib-wayland-ivi-egl-es-3-0.so.27.0 2>&1 | grep -iE 'egl|gles|wayland|not found'
