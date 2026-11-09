#!/bin/bash
# Keeps carsim running inside the long-lived launcher session (WSL kills processes started by
# short wsl.exe calls). restart.sh kills the carsim process; this loop relaunches it with the
# current carsim.conf.   supervisor.sh <rootfs> <emu-src> <qemu-cpu>
R=$1; SRC=$2; CPU=${3:-cortex-a76}
while true; do
  tr -d '\r' < "$SRC/carsim/carsim.conf" > $R/opt/emu/carsim.conf
  cd / && env -i PATH=/usr/sbin:/usr/bin:/sbin:/bin QEMU_CPU=$CPU LD_LIBRARY_PATH=/usr/lib:/lib \
    DLT_LOCAL_PRINT_MODE=FORCE_ON DLT_INITIAL_LOG_LEVEL=::5 \
    chroot $R /opt/emu/carsim /opt/emu/carsim.conf /tmp/carsim.fifo > /srv/mgu22/carsim.log 2>&1
  sleep 1
done
