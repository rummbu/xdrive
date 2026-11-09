#!/bin/bash
R=/srv/mgu22/root
ls $R/var/begu/hmi-data/bmw | head -5
ls $R/var/begu/hmi-vehicles/g26bev | head -5
export LD_LIBRARY_PATH=/opt/ivi/rootfs/usr/lib/hmi:/opt/ivi/rootfs/usr/lib:/opt/ivi/rootfs/lib:/opt/ext/rootfs/usr/lib:/opt/ext/rootfs/lib
echo '== Hmi8 not found'
chroot $R /lib/ld-linux-aarch64.so.1 --list /opt/ivi/rootfs/usr/bin/Hmi8 2>&1 | grep -E 'not found|rror' | sort -u | head -30
echo '== ramses EGL/wayland deps'
chroot $R /lib/ld-linux-aarch64.so.1 --list /opt/ivi/rootfs/usr/lib/libramses-shared-lib-wayland-ivi-egl-es-3-0.so.27.0 2>&1 | grep -iE 'egl|gles|wayland|ivi|not found'
