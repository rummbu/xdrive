#!/bin/bash
# Install + start a native x86 virgl vtest server on the WSL GPU, then probe it from the arm64 chroot.
R=/srv/mgu22/root
command -v virgl_test_server >/dev/null || DEBIAN_FRONTEND=noninteractive apt-get install -y -qq virgl-server mesa-utils >/dev/null
virgl_test_server --help 2>&1 | head -20
echo "== host GL (what the server will render with) =="
GALLIUM_DRIVER=d3d12 eglinfo -B -p surfaceless 2>/dev/null | grep -iE 'renderer|OpenGL ES profile version' | head -4
pkill -f virgl_test_server; sleep 0.3
mkdir -p $R/tmp; rm -f $R/tmp/.virgl_test
GALLIUM_DRIVER=d3d12 nohup virgl_test_server --use-egl-surfaceless --use-gles --multi-clients \
  --socket-path $R/tmp/.virgl_test > /srv/mgu22/virgl.log 2>&1 &
sleep 1; ls -la $R/tmp/.virgl_test; tail -3 /srv/mgu22/virgl.log
echo "== arm64 guest through virpipe =="
M=/opt/mesa/usr/lib/aarch64-linux-gnu
chroot $R /usr/bin/env -i LD_LIBRARY_PATH=$M:/opt/mesa/lib/aarch64-linux-gnu \
  __EGL_VENDOR_LIBRARY_FILENAMES=/opt/mesa/usr/share/glvnd/egl_vendor.d/50_mesa.json \
  LIBGL_DRIVERS_PATH=$M/dri LIBGL_ALWAYS_SOFTWARE=1 GALLIUM_DRIVER=virpipe VTEST_SOCKET_NAME=/tmp/.virgl_test \
  QEMU_CPU=cortex-a76 /opt/mesa/usr/bin/eglinfo -B -p surfaceless 2>&1 | grep -iE 'renderer|version|error|fail' | head -8
