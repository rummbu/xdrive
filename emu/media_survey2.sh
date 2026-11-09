#!/bin/bash
R=/srv/mgu22/root
for base in $R $R/opt/ivi/rootfs; do ls $base/etc/mediaconfig 2>/dev/null | sed "s|^|$base/etc/mediaconfig/|"; done
C=$(ls $R/etc/mediaconfig/mediaindexer_config_hu.xml $R/opt/ivi/rootfs/etc/mediaconfig/mediaindexer_config_hu.xml 2>/dev/null | head -1)
echo "== indexer: mount / device config ($C) =="
grep -iE 'mount|path|usb|device|storage|folder|dir' "$C" | head -25
E=$(ls $R/etc/mediaconfig/mediaengine_config_hu.xml $R/opt/ivi/rootfs/etc/mediaconfig/mediaengine_config_hu.xml 2>/dev/null | head -1)
echo "== engine: sinks / pulse ($E) =="
grep -iE 'sink|pulse|alsa|harman|device|output' "$E" | head -20
echo "== /etc/pulse =="; ls $R/etc/pulse 2>/dev/null; grep -vE '^\s*(#|;|$)' $R/etc/pulse/client.conf 2>/dev/null | head
echo "== WSLg pulse =="; ls -la /mnt/wslg/PulseServer 2>&1
