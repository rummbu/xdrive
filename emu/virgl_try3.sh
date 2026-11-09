#!/bin/bash
R=/srv/mgu22/root
M=/opt/mesa/usr/lib/aarch64-linux-gnu
pkill -f virgl_test_server; sleep 0.3; rm -f $R/tmp/.virgl_test
GALLIUM_DRIVER=${1:-d3d12} virgl_test_server --use-egl-surfaceless --use-gles --multi-clients --socket-path $R/tmp/.virgl_test > /tmp/vs.log 2>&1 &
sleep 1
ls /srv/mgu22/root/opt/mesa/usr/bin/ | head
chroot $R /usr/bin/env -i LD_LIBRARY_PATH=$M:/opt/mesa/lib/aarch64-linux-gnu \
  __EGL_VENDOR_LIBRARY_FILENAMES=/opt/mesa/usr/share/glvnd/egl_vendor.d/50_mesa.json \
  LIBGL_DRIVERS_PATH=$M/dri LIBGL_ALWAYS_SOFTWARE=1 GALLIUM_DRIVER=virpipe VTEST_SOCKET_NAME=/tmp/.virgl_test \
  EGL_LOG_LEVEL=debug QEMU_CPU=cortex-a76 /opt/mesa/usr/bin/eglinfo 2>&1 | grep -vE '^\s+(GL_|EGL_)|^    ' | head -60
echo "== server log =="; cat /tmp/vs.log | head -20
pkill -f virgl_test_server
