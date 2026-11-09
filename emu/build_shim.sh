#!/bin/bash
# Build the aarch64 evdev ioctl shim into the chroot (/opt/emu/libevdevshim.so).
SRC="$(cat /srv/mgu22/repo_root)/emu"
R=/srv/mgu22/root
mkdir -p $R/opt/emu
tr -d '\r' < "$SRC/evdev-shim.c" > /srv/mgu22/evdev-shim.c
aarch64-linux-gnu-gcc -shared -fPIC -O2 -Wall -nostartfiles -o $R/opt/emu/libevdevshim.so /srv/mgu22/evdev-shim.c || exit 1
aarch64-linux-gnu-objdump -T $R/opt/emu/libevdevshim.so | grep -E 'GLIBC|ioctl'
# CommonAPI wire-format tracer (enabled by CAPI_TRACE_SVC)
tr -d '\r' < "$SRC/capi-trace.c" > /srv/mgu22/capi-trace.c
aarch64-linux-gnu-gcc -shared -fPIC -O2 -Wall -Wno-unused-function -o $R/opt/emu/libcapitrace.so /srv/mgu22/capi-trace.c -ldl || exit 1
echo SHIM_OK
