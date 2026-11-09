#!/bin/bash
R=/srv/mgu22/root
L=$(find $R/usr/lib $R/opt/ivi/rootfs/usr/lib $R/opt/ext/rootfs/usr/lib -name 'libcod.so*' -type f 2>/dev/null | head -1)
echo "libcod: $L"
strings -n 5 $L | grep -E '^/|\.(bin|dat|txt|xml|json|db|cod)$|getenv|COD_|cod_' | sort -u | head -50
echo "== who provides coding (services/bins)"
grep -rlE 'libcod|coding' $R/etc/systemd/system/*.service 2>/dev/null | head
ls $R/usr/bin | grep -iE 'cod' ; ls $R/opt/ivi/rootfs/usr/bin | grep -iE 'cod'
echo "== variant hints in Hmi8"
strings -n 5 $R/opt/ivi/rootfs/usr/bin/Hmi8 | grep -E '\{variant\}|variantName|VehicleVariant|eva_VEHICLE|G26BEV|-vp' | sort -u | head -20
echo "== MGU22_Coding.txt head"; head -30 $R/opt/ivi/rootfs/usr/share/hmi/data/ro/MGU22_Coding.txt
grep -nE 'G26|BAUREIHE|TYPE_KEY|VEHICLE|Vehicle' $R/opt/ivi/rootfs/usr/share/hmi/data/ro/MGU22_Coding.txt | head -15
