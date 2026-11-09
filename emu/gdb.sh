#!/bin/bash
# Catch Hmi8's fatal signal under qemu's gdbstub and print where it is.
R=/srv/mgu22/root
command -v gdb-multiarch >/dev/null || DEBIAN_FRONTEND=noninteractive apt-get install -y -qq gdb-multiarch >/dev/null 2>&1
bash /srv/mgu22/setup.sh >/dev/null
M=/opt/mesa/usr/lib/aarch64-linux-gnu
export LD_LIBRARY_PATH=$M:/opt/ivi/rootfs/usr/lib/hmi:/opt/ivi/rootfs/usr/lib:/opt/ivi/rootfs/lib:/opt/ext/rootfs/usr/lib:/opt/ext/rootfs/lib
export __EGL_VENDOR_LIBRARY_FILENAMES=/opt/mesa/usr/share/glvnd/egl_vendor.d/50_mesa.json LIBGL_ALWAYS_SOFTWARE=1 LC_ALL=C
export XDG_RUNTIME_DIR=/var/run/wayland WAYLAND_DISPLAY=wayland-0 DISABLE_UPDATER_THREAD=1 QEMU_CPU=${QEMU_CPU:-cortex-a76}
QEMU_GDB=1234 chroot $R /opt/ivi/rootfs/usr/bin/Hmi8 -bsc -ap=/opt/ivi/rootfs/usr/lib/hmi/applet \
  -ro=/opt/ivi/rootfs/usr/share/hmi/data/ro/ -ibaroot=/var/begu/IBA -rsurn=/var/data/rsu-shared/rsureleasenotes -lm=ramses_thread \
  > /srv/mgu22/gdbrun.log 2>&1 &
sleep 2
timeout 300 gdb-multiarch -q -batch \
  -ex "set sysroot $R" -ex 'set pagination off' -ex 'set confirm off' \
  -ex "file $R/opt/ivi/rootfs/usr/bin/Hmi8" \
  -ex 'target remote :1234' -ex 'continue' \
  -ex 'info registers pc lr sp' -ex 'x/6i $pc-8' -ex 'bt 25' \
  -ex 'info symbol $pc' -ex 'info symbol $lr' \
  -ex 'info sharedlibrary' 2>&1 | grep -vE '^(warning|Reading)' | head -120
kill %1 2>/dev/null
