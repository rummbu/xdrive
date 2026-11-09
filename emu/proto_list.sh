#!/bin/bash
cd /srv/mgu22/ramses-src/external/wayland-ivi-extension/ivi-extension-protocol
# print each server interface struct with its request handlers (compact)
awk '/^struct ivi_controller[a-z_]*_interface \{/{p=1} p{print} p&&/^\};/{p=0; print ""}' ivi-controller-server-protocol.h \
  | grep -vE '^\s*\*|/\*\*|^\s*$' | sed -E 's/^\s+//' | tr '\n' ' ' | sed 's/};/};\n/g'
echo
grep -nE '"ivi_controller[a-z_]*", [0-9]+' ivi-controller-protocol.c
grep -cE 'wl_message' ivi-controller-protocol.c
