#!/bin/bash
R=/srv/mgu22/root
VD=$R/opt/ivi/rootfs/usr/share/hmi/data/ro/vehicles/widgetasset/vehicles
echo "== $VD =="; ls -la $VD
echo "== G05 =="; ls -la $VD/G05 | head; du -sh $VD/G05 2>/dev/null
echo "== G80LCI pack =="; ls -la $R/var/begu/hmi-vehicles/G80LCI | head -20; du -sh $R/var/begu/hmi-vehicles/G80LCI
echo "== G26BEV pack =="; ls $R/var/begu/hmi-vehicles/G26BEV | head
echo "== HMI log about vehicle model =="
grep -aiE 'vehicle(model|variant|series|type)|G05|G80|G26|widgetasset/vehicles' /srv/mgu22/hmi.log | cut -c95-300 | sort | uniq -c | sort -rn | head -15
echo "== Hmi8 strings: how variant is chosen =="
strings -n 6 $R/opt/ivi/rootfs/usr/bin/Hmi8 | grep -iE 'default.?vehicle|fallback.?vehicle|vehicleVariant|VEHICLE_VARIANT|SYSTEM_VEHICLE|vehicle series|Baureihe|getVehicleSeries' | sort -u | head -20
