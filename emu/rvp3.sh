#!/bin/bash
R=/srv/mgu22/root
strings -n 2 -t x $R/usr/lib/libcod.so.0.1.1 | awk '{o=strtonum("0x"$1)} o>=0x40d0 && o<=0x4190'
echo "== rvp-symlinks.ini"; head -40 $R/etc/rvp-symlinks.ini
