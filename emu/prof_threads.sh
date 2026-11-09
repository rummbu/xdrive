#!/bin/bash
# Per-thread CPU of the running Hmi8 over a sample window: who eats the time?
P=$(pgrep -f 'qemu-aarch64-static /opt/ivi/rootfs/usr/bin/Hmi8' | head -1)
[ -z "$P" ] && { echo "Hmi8 not running"; exit 1; }
S=${1:-10}
snap() { for t in /proc/$P/task/*; do echo "$(basename $t) $(cat $t/comm | tr ' ' _) $(awk '{print $14+$15}' $t/stat)"; done | sort; }
snap > /tmp/a; sleep $S; snap > /tmp/b
HZ=$(getconf CLK_TCK)
join /tmp/a /tmp/b | awk -v hz=$HZ -v s=$S '{d=$5-$3; if (d>0) printf "%6.1f%%  %s\n", 100*d/hz/s, $2}' | sort -rn | head -20
echo "--- by thread name (summed) ---"
join /tmp/a /tmp/b | awk -v hz=$HZ -v s=$S '{d=$5-$3; n=$2; sub(/[-:]?[0-9]+$/,"",n); a[n]+=d} END{for(k in a) if(a[k]>0) printf "%6.1f%%  %s\n",100*a[k]/hz/s,k}' | sort -rn | head
echo "cores: $(nproc)"
