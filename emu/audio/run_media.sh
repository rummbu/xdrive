#!/bin/bash
# Start BMW's media stack (mediaengine / mediaindexer / mediaapp) in the chroot, with ALSA "HarmanX"
# routed to WSLg PulseAudio. Logs: /srv/mgu22/svc-<name>.log.   run_media.sh <rootfs> <qemu-cpu>
R=$1; CPU=${2:-cortex-a76}
SRC="$(cat /srv/mgu22/repo_root)/emu/audio"
tr -d '\r' < "$SRC/setup_audio.sh" | bash
mkdir -p $R/var/opt/ent/share/covers/hu $R/run/wayland
# These services normally run in the IVI container whose /etc is /opt/ivi/rootfs/etc: expose the
# entries the main rootfs doesn't have (never overwrite existing ones).
for e in $R/opt/ivi/rootfs/etc/*; do
  n=$(basename "$e"); [ -e "$R/etc/$n" ] || [ -L "$R/etc/$n" ] || ln -s "/opt/ivi/rootfs/etc/$n" "$R/etc/$n"
done
media() { # name  extra-env...  --  command...
  local n=$1; shift; local envs=()
  while [ "$1" != "--" ]; do envs+=("$1"); shift; done; shift
  pkill -f "rootfs/usr/bin/$n " 2>/dev/null
  ( cd / && env -i PATH=/usr/sbin:/usr/bin:/sbin:/bin QEMU_CPU=$CPU LC_ALL=C ECU=MGU_02_L HWVAR=highf \
      DLT_LOCAL_PRINT_MODE=FORCE_ON DLT_INITIAL_LOG_LEVEL=::3 "${envs[@]}" \
      chroot $R "$@" > /srv/mgu22/svc-$n.log 2>&1 & )
  echo "media service $n started"
}
LIB=/opt/ivi/rootfs/usr/lib:/opt/ivi/rootfs/lib:/opt/ext/rootfs/usr/lib:/opt/ext/rootfs/usr/lib/pulseaudio:/opt/ext/rootfs/usr/lib/alsa-lib:/usr/lib:/lib
media mediaengine LD_LIBRARY_PATH=$LIB XDG_RUNTIME_DIR=/run/wayland PULSE_SERVER=unix:/run/pulse-wslg/native \
  -- /opt/ivi/rootfs/usr/bin/mediaengine -c /etc/mediaconfig/mediaengine_config_hu.xml -i MENG
media mediaindexer LD_LIBRARY_PATH=$LIB \
  -- /opt/ivi/rootfs/usr/bin/mediaindexer -c /etc/mediaconfig/mediaindexer_config_hu.xml -i MIND
media mediaapp LD_LIBRARY_PATH=$LIB COMMONAPI_CONFIG=/etc/conn_commonapi.ini COMMONAPI_DBUS_CONFIG=/etc/conn_commonapi-dbus.ini \
  -- /opt/ivi/rootfs/usr/bin/mediaapp -v /etc/mediaconfig/mediaapp_variant_select.xml -i MAPP
