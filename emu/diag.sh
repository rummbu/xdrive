#!/bin/bash
# Sync scripts from the Windows project dir, run Hmi8 for N seconds, summarize logs.
SRC="$(cat /srv/mgu22/repo_root)/emu"
for f in setup.sh run_hmi.sh mgu-ivi-controller.c; do tr -d '\r' < "$SRC/$f" > /srv/mgu22/$f; done
P=/srv/mgu22/ramses-src/external/wayland-ivi-extension/ivi-extension-protocol
gcc -shared -fPIC -O2 -Wall -Wno-unused-parameter -I$P -o /srv/mgu22/mgu-ivi-controller.so \
  /srv/mgu22/mgu-ivi-controller.c $P/ivi-controller-protocol.c $(pkg-config --cflags --libs libweston-13 wayland-server) || exit 1
HMI_TIMEOUT=${1:-120} bash /srv/mgu22/run_hmi.sh
L=/srv/mgu22/hmi.log
echo "=== weston mgu-ivi"; grep mgu-ivi /srv/mgu22/weston.log
echo "=== hmi.log $(wc -l < $L) lines; DLT lines: $(grep -c 'DLT\|\[.*\] [0-9]* [A-Z]' $L)"
echo "=== errors/fatals (dedup)"
grep -iE '\b(error|fatal|fail|assert|abort|timeout|missing|cannot|not found)\b' $L | grep -vE 'cei::|local_client_endpoint|vsomeip.lck' | sed -E 's/^[0-9:. -]+//' | awk '!s[$0]++' | head -40
echo "=== ramses / display / lifecycle / wait (dedup)"
grep -iE 'ramses|display|wayland|ivi|egl|surface|lifecycle|startup|nsm|nodestate|waiting|wait for|state' $L | grep -vE 'cei::|REGISTER EVENT|offer_event' | sed -E 's/^[0-9:. -]+//' | awk '!s[$0]++' | head -50
echo "=== brand / variant / optional dirs / coding"
grep -iE 'brand|variant|optional|data path|coding|vehicle|resolution|display ?size|config\.' $L | grep -vE 'Registering function|REGISTER|offer_event' | sed -E 's/^[0-9/:. -]+[0-9]+ [0-9]+ ECU1 //' | awk '!s[$0]++' | head -40
echo "=== last 30 distinct lines"
grep -vE 'cei::|local_client_endpoint|on_disconnect' $L | tail -30
pkill -f 'weston.*mgu22'; pkill -f /usr/bin/vsomeipd; pkill -f Hmi8
