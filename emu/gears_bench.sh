#!/bin/bash
# FPS of arm64 es2gears in the emulator's weston: virpipe(host GPU) vs emulated llvmpipe.
R=/srv/mgu22/root
M=/opt/mesa/usr/lib/aarch64-linux-gnu
pkill -f Hmi8; sleep 0.5
# private headless weston (desktop shell, so es2gears' xdg_shell works)
mkdir -p $R/var/run/wayland && chmod 700 $R/var/run/wayland
XDG_RUNTIME_DIR=$R/var/run/wayland weston --backend=headless --socket=bench-0 --width=1920 --height=640 >/tmp/wbench.log 2>&1 &
WP=$!; sleep 2
gears() { # $1 = gallium driver
  timeout ${2:-12} chroot $R /usr/bin/env -i LD_LIBRARY_PATH=$M:/opt/mesa/lib/aarch64-linux-gnu \
    __EGL_VENDOR_LIBRARY_FILENAMES=/opt/mesa/usr/share/glvnd/egl_vendor.d/50_mesa.json \
    LIBGL_DRIVERS_PATH=$M/dri LIBGL_ALWAYS_SOFTWARE=1 GALLIUM_DRIVER=$1 VTEST_SOCKET_NAME=/tmp/.virgl_test \
    XDG_RUNTIME_DIR=/var/run/wayland WAYLAND_DISPLAY=bench-0 QEMU_CPU=cortex-a76 \
    /opt/mesa/usr/bin/es2gears_wayland 2>&1 | grep -iE 'fps|GL_RENDERER|error|fail' | head -6
}
for drv in ${DRVS:-d3d12 llvmpipe}; do
  pkill -f virgl_test_server; sleep 0.3; rm -f $R/tmp/.virgl_test
  GALLIUM_DRIVER=$drv virgl_test_server --use-egl-surfaceless ${GLES:---use-gles} --multi-clients --socket-path $R/tmp/.virgl_test > /tmp/vs_$drv.log 2>&1 &
  sleep 1
  echo "### virpipe -> host $drv"; gears virpipe
  echo "server log:"; head -5 /tmp/vs_$drv.log
done
pkill -f virgl_test_server
echo "### emulated llvmpipe (current default)"; gears llvmpipe
kill $WP
