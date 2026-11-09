#!/bin/bash
# Does virgl_test_server work at all on this WSL GPU? Test with a native x86 virpipe client.
S=/tmp/.vt_host
for drv in d3d12 llvmpipe zink; do
 for gles in --use-gles ""; do
  pkill -f virgl_test_server; sleep 0.3; rm -f $S
  GALLIUM_DRIVER=$drv MESA_LOADER_DRIVER_OVERRIDE= virgl_test_server --use-egl-surfaceless $gles --socket-path $S > /tmp/vh.log 2>&1 &
  sleep 0.8
  r=$(GALLIUM_DRIVER=virpipe VTEST_SOCKET_NAME=$S LIBGL_ALWAYS_SOFTWARE=1 timeout 20 eglinfo -B -p surfaceless 2>&1 | grep -E 'OpenGL ES profile (renderer|version)' | tr '\n' ' ')
  echo "host=$drv ${gles:-desktopGL}: ${r:-<none>} | server: $(tr '\n' ' ' < /tmp/vh.log | cut -c1-150)"
 done
done
pkill -f virgl_test_server
