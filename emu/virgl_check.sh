#!/bin/bash
R=/srv/mgu22/root
M=$R/opt/mesa/usr/lib/aarch64-linux-gnu
echo "== guest mesa: virpipe/vtest built in? =="
ls $M/dri/ | head -30
for f in $M/dri/swrast_dri.so $M/libgallium*.so; do [ -f "$f" ] && { echo "$f:"; strings -n 6 "$f" | grep -E 'virpipe|vtest|VTEST_SOCKET' | sort -u | head; }; done
echo "== host package =="
apt-cache policy virgl-server 2>/dev/null | head -3
apt-cache search virgl | head
echo "== host GPU in WSL =="
ls -la /dev/dxg 2>&1; ls /usr/lib/wsl/lib 2>/dev/null | head
eglinfo -B 2>/dev/null | grep -iE 'renderer|version' | head -6 || echo "no eglinfo"
