#!/bin/bash
# Thread CPU over the first ~45 s of an HMI boot.
for i in $(seq 100); do pgrep -f 'qemu-aarch64-static /opt/ivi/rootfs/usr/bin/Hmi8' >/dev/null && break; sleep 0.3; done
SRC="$(cat /srv/mgu22/repo_root)/emu"
sleep 3
tr -d '\r' < "$SRC/prof_threads.sh" | bash -s 40 2>/dev/null | sed -n '/summed/,$p'
