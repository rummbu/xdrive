#!/bin/bash
# Build the weston ivi controller module (with GENIVI ivi_controller protocol) into /srv/mgu22.
SRC="$(cat /srv/mgu22/repo_root)/emu"
P=/srv/mgu22/ramses-src/external/wayland-ivi-extension/ivi-extension-protocol
tr -d '\r' < "$SRC/mgu-ivi-controller.c" > /srv/mgu22/mgu-ivi-controller.c
gcc -shared -fPIC -O2 -Wall -Wno-unused-parameter -Wno-unused-function -I$P -o /srv/mgu22/mgu-ivi-controller.so \
  /srv/mgu22/mgu-ivi-controller.c $P/ivi-controller-protocol.c $(pkg-config --cflags --libs libweston-13 wayland-server) \
  && echo BUILD-OK
