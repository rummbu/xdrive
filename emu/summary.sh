#!/bin/bash
L=/srv/mgu22/hmi.log
strip() { sed -E 's/^[0-9/:. -]+[0-9]+ [0-9]+ ECU1 //' | awk '!s[$0]++' | cut -c1-230; }
echo "=== weston mgu-ivi"; grep mgu-ivi /srv/mgu22/weston.log
echo "=== mounts"; mount | grep -o '/srv/mgu22/root/var/begu[^ ]*'
echo "=== hmi.log $(wc -l < $L) lines"
echo "=== brand / variant / optional / coding / vehicle"
grep -iE 'brand|variant|optional|data path|coding|vehicle|resolution|config\.' $L | grep -vE 'Registering function|REGISTER|offer_event' | strip | head -40
echo "=== ramses / display / surface / wayland"
grep -iE 'ramses|wayland|ivi[^a-z]|egl|surface|renderer|framebuffer' $L | grep -vE 'Registering function|REGISTER|offer_event' | strip | head -30
echo "=== cod / coding / window"
grep -iE 'cod_|coding|generateWindow|resolution|display-size|window' $L | grep -vE 'Registering function|REGISTER|offer_event|^\[-' | strip | head -30
echo "=== last 15 non-timer lines"
grep -vE 'cei::|local_client_endpoint|on_disconnect|tHMI_Timer|STAT|Mainloop did not' $L | tail -15 | strip
