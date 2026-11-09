#!/bin/bash
# What do the media services wait for regarding devices/sources?
SRC="$(cat /srv/mgu22/repo_root)/emu/audio"
tr -d '\r' < "$SRC/run_media.sh" | bash -s /srv/mgu22/root cortex-a76 >/dev/null
sleep 60
for s in mediaapp mediaindexer; do
  echo "== $s: device/mount/usb/unavailable lines"
  grep -aiE 'usb|mount|device|storage|udev|not available|unavailable|waiting' /srv/mgu22/svc-$s.log | grep -avE 'Adreno|DLT\[' | cut -c60-260 | sed -E 's/T[0-9]+ / /' | sort | uniq -c | sort -rn | head -15
done
echo "== indexer config: device sources"
grep -iE '<(Device|Source|Mount|Media|Usb)[A-Za-z]*>' /srv/mgu22/root/opt/ivi/rootfs/etc/mediaconfig/mediaindexer_config_hu.xml | head -20
