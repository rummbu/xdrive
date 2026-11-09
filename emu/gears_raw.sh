#!/bin/bash
R=/srv/mgu22/root
M=/opt/mesa/usr/lib/aarch64-linux-gnu
mkdir -p $R/var/run/wayland && chmod 700 $R/var/run/wayland
XDG_RUNTIME_DIR=$R/var/run/wayland weston --backend=headless --socket=bench-0 --width=1920 --height=640 >/tmp/wbench.log 2>&1 &
WP=$!; sleep 2; ls -la $R/var/run/wayland/
timeout 12 chroot $R /usr/bin/env -i LD_LIBRARY_PATH=$M:/opt/mesa/lib/aarch64-linux-gnu \
    __EGL_VENDOR_LIBRARY_FILENAMES=/opt/mesa/usr/share/glvnd/egl_vendor.d/50_mesa.json \
    LIBGL_DRIVERS_PATH=$M/dri LIBGL_ALWAYS_SOFTWARE=1 GALLIUM_DRIVER=${1:-llvmpipe} VTEST_SOCKET_NAME=/tmp/.virgl_test \
    XDG_RUNTIME_DIR=/var/run/wayland WAYLAND_DISPLAY=bench-0 QEMU_CPU=cortex-a76 \
    /opt/mesa/usr/bin/es2gears_wayland 2>&1 | head -20
echo "rc=$?"; tail -5 /tmp/wbench.log
kill $WP
