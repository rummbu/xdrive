#!/bin/bash
# Cross-build carsim (aarch64) against the firmware's own vsomeip 3.5.0 + GCC 11 libstdc++.
set -e
SRC="$(cat /srv/mgu22/repo_root)/emu/carsim"
R=/srv/mgu22/root
INC=/srv/mgu22/vsomeip-src/interface
mkdir -p $R/opt/emu
tr -d '\r' < "$SRC/carsim.cpp" > /srv/mgu22/carsim.cpp
aarch64-linux-gnu-g++-11 -std=c++17 -O2 -I$INC -o $R/opt/emu/carsim /srv/mgu22/carsim.cpp \
  -L$R/usr/lib -Wl,-rpath-link,$R/usr/lib -Wl,-rpath-link,$R/lib -l:libvsomeip3.so.3 -lpthread
# must not need anything newer than the firmware's glibc 2.35 / GLIBCXX 3.4.29
aarch64-linux-gnu-objdump -T $R/opt/emu/carsim | grep -oE 'GLIBC(XX)?_[0-9.]+' | sort -uV | tail -3
echo CARSIM_OK
