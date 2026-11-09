#!/bin/bash
# Fast EGL-on-wayland check inside the chroot, same env as Hmi8, with Mesa debug logging.
R=/srv/mgu22/root
SRC="$(cat /srv/mgu22/repo_root)/emu"
bash /srv/mgu22/setup.sh >/dev/null
[ -x $R/opt/mesa/usr/bin/es2_info ] || python3 -I "$SRC/fetch_mesa.py" $R/opt/mesa mesa-utils-bin mesa-utils 2>&1 | tail -2
ls $R/opt/mesa/usr/bin/ 2>/dev/null | tr '\n' ' '; echo
ls $R/opt/mesa/usr/lib/aarch64-linux-gnu/dri/ | grep -E 'swrast|kms' ; ls -la $R/dev/dri 2>&1 | head -3
# compositor
RT=$R/var/run/wayland; mkdir -p $RT; pkill -f 'weston.*mgu22'; sleep 0.3
XDG_RUNTIME_DIR=$RT WAYLAND_DISPLAY=/mnt/wslg/runtime-dir/wayland-0 weston --backend=wayland-backend.so \
  --config=/srv/mgu22/weston.ini --socket=wayland-0 --width=1440 --height=540 --log=/srv/mgu22/weston-egl.log 2>/dev/null &
for i in $(seq 50); do [ -S $RT/wayland-0 ] && break; sleep 0.2; done
M=/opt/mesa/usr/lib/aarch64-linux-gnu
export QEMU_CPU=cortex-a76 XDG_RUNTIME_DIR=/var/run/wayland WAYLAND_DISPLAY=wayland-0
export LD_LIBRARY_PATH=$M:/opt/mesa/lib/aarch64-linux-gnu:/opt/ivi/rootfs/usr/lib:/opt/ext/rootfs/usr/lib
export __EGL_VENDOR_LIBRARY_FILENAMES=/opt/mesa/usr/share/glvnd/egl_vendor.d/50_mesa.json
export LIBGL_DRIVERS_PATH=$M/dri LIBGL_ALWAYS_SOFTWARE=1 GALLIUM_DRIVER=llvmpipe EGL_PLATFORM=wayland
export EGL_LOG_LEVEL=debug MESA_DEBUG=1 LIBGL_DEBUG=verbose
unset EGL_LOG_LEVEL LIBGL_DEBUG
echo "=== eglinfo (wayland section)"
timeout 180 chroot $R /opt/mesa/usr/bin/eglinfo 2>&1 | awk '/^Wayland platform:/{p=1} p' | grep -E 'platform|EGL API|EGL vendor|EGL version|OpenGL ES profile (vendor|renderer|version)|failed' | head -12
echo "=== es2gears_wayland 25s (should draw in the weston window)"
timeout 25 chroot $R /opt/mesa/usr/bin/es2gears_wayland 2>&1 | tail -4
grep -c 'new surface' /srv/mgu22/weston-egl.log
pkill -f 'weston.*mgu22'
