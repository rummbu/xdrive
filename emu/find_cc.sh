#!/bin/bash
# Where do check-control texts live? Search HMI data for misfire/drivetrain wording.
R=/srv/mgu22/root
for d in $R/var/begu/hmi-data/bmw $R/var/begu/hmi-data/bmwm $R/var/begu/hmi-data/bmw-shared $R/opt/ivi/rootfs/usr/share/hmi/data/ro; do
  find -L $d -maxdepth 4 \( -name '*.db' -o -name '*.sqlite' \) 2>/dev/null
done | sort -u | head -20
echo "== files containing 'misfir' =="
grep -rlaiE 'misfir|Zündaussetzer' $R/var/begu/hmi-data/bmw/db $R/var/begu/hmi-data/bmwm 2>/dev/null | head
