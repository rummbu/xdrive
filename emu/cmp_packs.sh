#!/bin/bash
R=/srv/mgu22/root
VD=$R/opt/ivi/rootfs/usr/share/hmi/data/ro/vehicles/widgetasset/vehicles
mountpoint -q $VD/G05 && umount $VD/G05
echo "== original G05 (X5) =="; (cd $VD/G05 && find . -maxdepth 3 | sort | head -40)
echo "== G80LCI =="; (cd $R/var/begu/hmi-vehicles/G80LCI && find . -maxdepth 3 | sort | head -40)
echo "== strings in widget.pbw that look like names =="
strings -n 4 $VD/G05/TRIMA/vehicle_G05/widget.pbw 2>/dev/null | grep -iE 'g05|vehicle|scene' | head -8
echo "--"
strings -n 4 $R/var/begu/hmi-vehicles/G80LCI/TRIMA/vehicle_G80LCI/widget.pbw | grep -iE 'g80|vehicle|scene' | head -8
