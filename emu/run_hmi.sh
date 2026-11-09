#!/bin/bash
# Boot the real MGU22 Hmi8 (iDrive 8.5) under qemu-aarch64 in a chroot, rendering into an
# ivi-shell Weston that shows up as a window on the Windows desktop via WSLg.
#   HMI_TIMEOUT=seconds (0 = run until killed)   W=1440 H=540 window size (HMI is scaled to fit)
R=/srv/mgu22/root
W=${W:-1440}; H=${H:-540}
EMU=$(dirname "$(readlink -f "$0")")
EMU_SRC="$(cat /srv/mgu22/repo_root)/emu"
T=${HMI_TIMEOUT:-0}
bash "$EMU/setup.sh" >/dev/null || exit 1

# ---- compositor: weston + ivi-shell + hmi-controller, nested in WSLg
RT=$R/var/run/wayland
mkdir -p $RT && chmod 700 $RT
pkill -f 'weston.*mgu22' 2>/dev/null; sleep 0.3
# profile: project config section (theme/display) + CID panel size for the touchscreen
# (Hmi8 reads it from its persistence dir, and rewrites it with whatever section it ended up on)
FCS=$R/var/opt/public/hmi/hmi_id8main/fallback_config_section
mkdir -p $(dirname $FCS)
echo "${CONFIG_SECTION:-config.bmw_id8_display12_3_1920x720_Rueko}" > $FCS
export MGU_TSC_W=${SCREEN_W:-1920} MGU_TSC_H=${SCREEN_H:-640}
echo "profile: $(cat /srv/mgu22/profile 2>/dev/null) brand=${BRAND:-bmw} variant=${VARIANT:-G26BEV} config=${CONFIG_SECTION:-default} ${MGU_TSC_W}x${MGU_TSC_H}"
# the compositor module creates the CID touch panel (cid-tsc) through uinput; Hmi8 opens it at start
modprobe uinput 2>/dev/null; rm -f /dev/input/cid-touchscreen
cat > /srv/mgu22/weston.ini <<EOF
[core]
shell=ivi-shell.so
modules=/srv/mgu22/mgu-ivi-controller.so
idle-time=0
[shell]
locking=false
[output]
name=wayland0
mode=${W:-1920}x${H:-720}
EOF
XDG_RUNTIME_DIR=$RT WAYLAND_DISPLAY=/mnt/wslg/runtime-dir/wayland-0 \
  weston --backend=wayland-backend.so --config=/srv/mgu22/weston.ini --socket=wayland-0 \
         --width=${W:-1920} --height=${H:-720} --log=/srv/mgu22/weston.log --idle-time=0 --debug 2>/dev/null &
# --debug exposes weston_screenshooter so shot.sh can grab frames even while Windows is locked
for i in $(seq 50); do [ -S $RT/wayland-0 ] && break; sleep 0.2; done
[ -S $RT/wayland-0 ] || { echo "weston failed:"; tail -30 /srv/mgu22/weston.log; exit 1; }
echo "weston up"

# ---- the HMI
M=/opt/mesa/usr/lib/aarch64-linux-gnu
export DISABLE_UPDATER_THREAD=1 XDG_RUNTIME_DIR=/var/run/wayland WAYLAND_DISPLAY=wayland-0 LC_ALL=C
export HMI_TOUCH_INPUT_DEVICE=/dev/input/cid-touchscreen
export LD_LIBRARY_PATH=$M:/opt/mesa/lib/aarch64-linux-gnu:/opt/ivi/rootfs/usr/lib/hmi:/opt/ivi/rootfs/usr/lib:/opt/ivi/rootfs/lib:/opt/ext/rootfs/usr/lib:/opt/ext/rootfs/lib
export __EGL_VENDOR_LIBRARY_FILENAMES=/opt/mesa/usr/share/glvnd/egl_vendor.d/50_mesa.json
export LIBGL_DRIVERS_PATH=$M/dri GBM_BACKENDS_PATH=$M/gbm LIBGL_ALWAYS_SOFTWARE=1
# Rendering. Under qemu, arm64 llvmpipe rasterizing on the CPU was ~95% of all CPU time.
#   RENDER=gpu (default): the arm64 Mesa only encodes GL commands (virpipe) and a native x86
#     virgl_test_server draws them on the real GPU through WSL's D3D12 driver.
#   RENDER=cpu: the old all-emulated llvmpipe path.
if [ "${RENDER:-gpu}" = gpu ] && command -v virgl_test_server >/dev/null; then
  pkill -f virgl_test_server 2>/dev/null; mkdir -p $R/tmp; rm -f $R/tmp/.virgl_test
  # --multi-clients breaks renderer init on WSL's D3D12; the default (fork per client) works
  # clean env: the arm64 Mesa variables exported above would send the x86 server to the wrong driver
  env -i PATH=/usr/sbin:/usr/bin:/sbin:/bin GALLIUM_DRIVER=${HOST_GALLIUM:-d3d12} \
    virgl_test_server --use-egl-surfaceless \
    --socket-path $R/tmp/.virgl_test > /srv/mgu22/virgl.log 2>&1 &
  for i in $(seq 50); do [ -S $R/tmp/.virgl_test ] && break; sleep 0.1; done
  export GALLIUM_DRIVER=virpipe VTEST_SOCKET_NAME=/tmp/.virgl_test
  echo "render: gpu (virpipe -> virgl_test_server on D3D12)"
else
  export GALLIUM_DRIVER=${GALLIUM_DRIVER:-llvmpipe}
  echo "render: cpu ($GALLIUM_DRIVER)"
fi
# RAMSES caches GL program binaries; llvmpipe and virgl binaries are incompatible (failed
# uploads -> black screen), so each render path gets its own cache directory.
SC=$R/var/opt/public/hmi/hmi_id8main
mkdir -p $SC
[ -d $SC/shader-cache ] && [ ! -L $SC/shader-cache ] && mv $SC/shader-cache $SC/shader-cache.llvmpipe-old
mkdir -p $SC/shader-cache.$GALLIUM_DRIVER
ln -sfn shader-cache.$GALLIUM_DRIVER $SC/shader-cache
export EGL_PLATFORM=wayland MESA_GLES_VERSION_OVERRIDE=3.2 MESA_GLSL_VERSION_OVERRIDE=320
# MGU22 = SA8155P (Kryo 485 / Cortex-A76). qemu's default 'max' CPU enables BTI, and Hmi8's
# PLT stubs have no landing pads -> SIGILL on the first indirect call. Emulate the real core.
export QEMU_CPU=${QEMU_CPU:-cortex-a76}
# no dlt-daemon here: make libdlt print the HMI's own diagnostic log to stdout
export ECU=MGU_02_L HWVAR=highf
# Level 3 = warnings. Info (4) logs dozens of lines per touch/frame; every one is formatted by
# emulated arm64 code, which made the UI noticeably laggier. Debug with DLT_LEVEL=::4.
export DLT_LOCAL_PRINT_MODE=FORCE_ON DLT_INITIAL_LOG_LEVEL="${DLT_LEVEL:-::3}"
# ---- SOME/IP bus: the car's own vsomeipd routing manager (configs use the HU's internal IP)
ip addr show dev lo | grep -q 160.48.199.99 || ip addr add 160.48.199.99/32 dev lo
mkdir -p $R/var/run/someip && chmod 777 $R/var/run/someip
pkill -f /usr/bin/vsomeipd 2>/dev/null; rm -f $R/var/run/someip/vsomeip-0 $R/var/run/someip/vsomeip.lck
# Clients only accept a routing manager running with the credentials in its security config
# (routing-credentials uid 4003017 / gid 5002, same as its config dir etc/vsomeip/mgu/4003017_5002).
# As root, every client refused it ("credentials do not match") and SOME/IP never came up.
DLT_LOCAL_PRINT_MODE=FORCE_ON DLT_INITIAL_LOG_LEVEL=::4 chroot --userspec=4003017:5002 $R /usr/bin/vsomeipd > /srv/mgu22/vsomeipd.log 2>&1 &
for i in $(seq 120); do [ -S $R/var/run/someip/vsomeip-0 ] && break; sleep 0.5; done
[ -S $R/var/run/someip/vsomeip-0 ] && echo "vsomeipd up" || { echo "vsomeipd failed:"; tail -20 /srv/mgu22/vsomeipd.log; }

# ---- other ECU-internal services from the dump that the HMI talks to (logs: /srv/mgu22/svc-<name>.log)
svc() { # name  command...
  local n=$1; shift
  pkill -f "rootfs/usr/bin/$n" 2>/dev/null
  ( cd / && env -i PATH=/usr/sbin:/usr/bin:/sbin:/bin QEMU_CPU=$QEMU_CPU LC_ALL=C ECU=MGU_02_L HWVAR=highf \
      LD_LIBRARY_PATH=/opt/ivi/rootfs/usr/lib:/opt/ivi/rootfs/lib:/opt/ext/rootfs/usr/lib:/opt/ext/rootfs/lib \
      DLT_LOCAL_PRINT_MODE=FORCE_ON DLT_INITIAL_LOG_LEVEL=::3 \
      chroot $R "$@" > /srv/mgu22/svc-$n.log 2>&1 & )
  echo "service $n started"
}
mkdir -p $R/var/opt/personal
svc persod /opt/ivi/rootfs/usr/bin/persod --ecu=MGU_02_L   # personalization = driver profiles
# media stack (mediaengine/mediaindexer/mediaapp) + ALSA "HarmanX" -> WSLg PulseAudio (Windows speakers)
tr -d '\r' < "$EMU_SRC/audio/run_media.sh" | bash -s $R $QEMU_CPU
# carsim: our simulated other ECUs (climate, vehicle data, cluster...), emu/carsim/
# Supervised from this (long-lived) session: WSL kills processes started by short wsl.exe calls,
# so carsim/restart.sh only refreshes the config and kills carsim; this loop brings it back.
pkill -f carsim_supervisor 2>/dev/null; pkill -f 'qemu-aarch64-static /opt/emu/carsim' 2>/dev/null
tr -d '\r' < "$EMU_SRC/carsim/supervisor.sh" > /srv/mgu22/carsim_supervisor.sh
( bash /srv/mgu22/carsim_supervisor.sh $R "$EMU_SRC" $QEMU_CPU & )
echo "service carsim started (supervised)"

# debugging: touch /srv/mgu22/strace.on to get qemu's syscall trace in hmi.log (very slow, huge)
[ -f /srv/mgu22/strace.on ] && export QEMU_STRACE=1
# qemu-user can't translate evdev ioctls; the shim answers them so mtdev can open the touch panel
# CAPI_TRACE_SVC=b09a,... (file /srv/mgu22/capi_trace) logs CommonAPI wire decoding into hmi.log
# (commas would split QEMU_SET_ENV's own list, so the tracer gets ':'-separated ids)
CAPI_TRACE_SVC=$(cat /srv/mgu22/capi_trace 2>/dev/null | tr -d ' \r\n' | tr ',' ':')
CMD=(env QEMU_SET_ENV=LD_PRELOAD=/opt/emu/libevdevshim.so:/opt/emu/libcapitrace.so,MGU_TSC_W=$MGU_TSC_W,MGU_TSC_H=$MGU_TSC_H,CAPI_TRACE_SVC=$CAPI_TRACE_SVC
  chroot $R /opt/ivi/rootfs/usr/bin/Hmi8 -bsc -brand=${BRAND:-bmw}
  -ap=/opt/ivi/rootfs/usr/lib/hmi/applet -ro=/opt/ivi/rootfs/usr/share/hmi/data/ro/
  -ibaroot=/var/begu/IBA -rsurn=/var/data/rsu-shared/rsureleasenotes -lm=ramses_thread)
# qemu 8.2 sometimes segfaults internally during boot ("QEMU internal SIGSEGV", a qemu race, not
# the HMI). If Hmi8 dies by SIGSEGV/SIGABRT (139/134), start it again; stop.ps1 (SIGINT) ends it.
for attempt in 1 2 3 4 5; do
  if [ "$T" -gt 0 ]; then timeout -s INT $T "${CMD[@]}" > /srv/mgu22/hmi.log 2>&1; else "${CMD[@]}" > /srv/mgu22/hmi.log 2>&1; fi
  rc=$?
  echo "hmi exit=$rc (attempt $attempt)"
  [ $rc -eq 139 ] || [ $rc -eq 134 ] || break
  grep -aq 'QEMU internal SIGSEGV' /srv/mgu22/hmi.log && cp /srv/mgu22/hmi.log /srv/mgu22/hmi.crash.log
  [ -S $R/tmp/.virgl_test ] || break
  sleep 1
done
