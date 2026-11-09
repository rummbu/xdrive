#!/bin/bash
# Which virgl_test_server mode initialises on WSL D3D12, and what GL does the arm64 guest get?
R=/srv/mgu22/root
M=/opt/mesa/usr/lib/aarch64-linux-gnu
probe() {
  chroot $R /usr/bin/env -i LD_LIBRARY_PATH=$M:/opt/mesa/lib/aarch64-linux-gnu \
    __EGL_VENDOR_LIBRARY_FILENAMES=/opt/mesa/usr/share/glvnd/egl_vendor.d/50_mesa.json \
    LIBGL_DRIVERS_PATH=$M/dri LIBGL_ALWAYS_SOFTWARE=1 GALLIUM_DRIVER=virpipe VTEST_SOCKET_NAME=/tmp/.virgl_test \
    EGL_PLATFORM=surfaceless QEMU_CPU=cortex-a76 /opt/mesa/usr/bin/eglinfo -p surfaceless 2>&1 \
    | grep -E 'OpenGL ES profile (renderer|version)|OpenGL core profile version|renderer' | sort -u | head -6
}
for mode in "--use-egl-surfaceless --use-gles" "--use-egl-surfaceless"; do
  for drv in d3d12 llvmpipe; do
    pkill -f virgl_test_server; sleep 0.3; rm -f $R/tmp/.virgl_test
    GALLIUM_DRIVER=$drv virgl_test_server $mode --multi-clients --socket-path $R/tmp/.virgl_test > /tmp/vs.log 2>&1 &
    sleep 1
    echo "### host=$drv mode=$mode"
    probe
    grep -i fail /tmp/vs.log | head -2
  done
done
pkill -f virgl_test_server
