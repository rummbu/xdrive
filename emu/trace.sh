#!/bin/bash
# Who loads Adreno, and what was the last thing Hmi8 did before SIGILL.
R=/srv/mgu22/root
bash /srv/mgu22/setup.sh >/dev/null
M=/opt/mesa/usr/lib/aarch64-linux-gnu
export LD_LIBRARY_PATH=$M:/opt/ivi/rootfs/usr/lib/hmi:/opt/ivi/rootfs/usr/lib:/opt/ivi/rootfs/lib:/opt/ext/rootfs/usr/lib:/opt/ext/rootfs/lib
echo "== Hmi8 deps resolving to EGL/GLES/adreno/gsl"
chroot $R /lib/ld-linux-aarch64.so.1 --list /opt/ivi/rootfs/usr/bin/Hmi8 2>&1 | grep -iE 'egl|gles|adreno|gsl|gbm|drm'
echo "== who NEEDs libEGL / adreno (scan hmi + ivi libs)"
for f in $R/opt/ivi/rootfs/usr/lib/*.so* $R/opt/ivi/rootfs/usr/lib/hmi/*.so*; do
  [ -f "$f" ] && [ ! -L "$f" ] || continue
  n=$(readelf -d "$f" 2>/dev/null | grep -oE 'Shared library: \[(libEGL|libGLESv2|libgsl|libadreno|libEGL_adreno)[^]]*' | tr '\n' ' ')
  [ -n "$n" ] && echo "$(basename $f): $n"
done | head -20
echo "== strace tail"
export __EGL_VENDOR_LIBRARY_FILENAMES=/opt/mesa/usr/share/glvnd/egl_vendor.d/50_mesa.json LIBGL_ALWAYS_SOFTWARE=1 LC_ALL=C
export XDG_RUNTIME_DIR=/var/run/wayland WAYLAND_DISPLAY=wayland-0 DISABLE_UPDATER_THREAD=1
QEMU_STRACE=1 timeout 120 chroot $R /opt/ivi/rootfs/usr/bin/Hmi8 -bsc -ap=/opt/ivi/rootfs/usr/lib/hmi/applet \
  -ro=/opt/ivi/rootfs/usr/share/hmi/data/ro/ -ibaroot=/var/begu/IBA -rsurn=/var/data/rsu-shared/rsureleasenotes -lm=ramses_thread \
  > /srv/mgu22/strace.log 2>&1
grep -E 'openat\(.*(adreno|gsl|EGL|GLES|kgsl)' /srv/mgu22/strace.log | grep -v ENOENT | head -12
echo ...
grep -cE 'adreno|gsl' /srv/mgu22/strace.log
grep -B2 -A2 SIGILL /srv/mgu22/strace.log | head; echo "--- tid of crash context"
T=$(grep -B1 SIGILL /srv/mgu22/strace.log | head -1 | awk '{print $1}'); grep "^$T " /srv/mgu22/strace.log | grep -E 'openat|execve|mmap.*PROT_EXEC|mprotect' | grep -v ENOENT | tail -15
tail -25 /srv/mgu22/strace.log
