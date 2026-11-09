#!/bin/bash
SRC="$(cat /srv/mgu22/repo_root)/emu"
R=/srv/mgu22/root
python3 -I "$SRC/gen_coding.py" $R/usr/share/sysfunc/coding/cafd_mgu_02_l.bin \
  $R/opt/ivi/rootfs/usr/share/hmi/data/ro/MGU22_Coding.txt "$SRC/coding/${1:-m3}.txt" /tmp/ncdtest
ls -la /tmp/ncdtest
