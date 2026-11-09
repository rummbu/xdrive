#!/bin/bash
# Run BMW's personalization daemon (driver profiles) in the chroot. run_persod.sh [seconds]
R=/srv/mgu22/root
pkill -f 'bin/persod' 2>/dev/null; sleep 0.3
mkdir -p $R/var/opt/personal $R/var/opt/public
cd /
env -i PATH=/usr/sbin:/usr/bin:/sbin:/bin QEMU_CPU=cortex-a76 \
  LD_LIBRARY_PATH=/opt/ivi/rootfs/usr/lib:/opt/ivi/rootfs/lib:/opt/ext/rootfs/usr/lib:/opt/ext/rootfs/lib \
  ECU=MGU_02_L HWVAR=highf DLT_LOCAL_PRINT_MODE=FORCE_ON DLT_INITIAL_LOG_LEVEL=${DLT_LEVEL:-::4} LC_ALL=C \
  timeout ${1:-40} chroot $R /opt/ivi/rootfs/usr/bin/persod --ecu=MGU_02_L > /srv/mgu22/persod.log 2>&1
echo "persod exit=$?"
grep -aiE 'error|fail|fatal|offer|available|started|ready' /srv/mgu22/persod.log | cut -c1-30,60-240 | head -30
echo "lines: $(wc -l < /srv/mgu22/persod.log)"; tail -5 /srv/mgu22/persod.log | cut -c1-220
