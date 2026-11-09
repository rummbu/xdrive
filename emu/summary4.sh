#!/bin/bash
L=/srv/mgu22/hmi.log
echo "=== RRND (renderer) lines: display / egl / wayland / ivi / errors, first occurrences"
grep -a 'RRND log' $L | grep -aviE 'Map scene|sceneMapped|initiating mapping|Failed to map scene' | sed -E 's/^.*RRND log //' | awk '!s[$0]++' | head -70
