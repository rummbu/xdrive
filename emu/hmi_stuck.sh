#!/bin/bash
# Is the HMI main thread stuck? What did it do last?
date
grep -a 'tHMI_App' /srv/mgu22/hmi.log | tail -${1:-15} | cut -c1-30,95-320
P=$(pgrep -f 'qemu-aarch64-static /opt/ivi/rootfs/usr/bin/Hmi8' | head -1)
for t in /proc/$P/task/*; do
  c=$(cat $t/comm)
  [ "$c" = tHMI_App ] && echo "$c state=$(awk '{print $3}' $t/stat) wchan=$(cat $t/wchan) cpu=$(awk '{print $14+$15}' $t/stat)"
done
