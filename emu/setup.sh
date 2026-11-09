#!/bin/bash
# One-time / per-boot setup of the MGU22 chroot: binfmt, SWFK mounts, pseudo filesystems.
set -u
R=/srv/mgu22/root
SW=/srv/mgu22/swfk

# aarch64 binfmt with F (fix-binary) so it works inside the chroot without copying qemu in
# Prefer Debian's qemu 10 (fetch_qemu.py) over Ubuntu's 8.2, which crashes internally on some
# GPU-mode boots. QEMU_OLD=1 forces the old one.
Q=/usr/bin/qemu-aarch64-static
[ -x /opt/qemu-new/qemu-aarch64-static ] && [ "${QEMU_OLD:-0}" != 1 ] && Q=/opt/qemu-new/qemu-aarch64-static
B=/proc/sys/fs/binfmt_misc/qemu-aarch64
if [ -e $B ] && ! grep -q "interpreter $Q\$" $B; then echo -1 > $B; fi   # registered with the other qemu
if [ ! -e $B ]; then
  echo ":qemu-aarch64:M::\x7fELF\x02\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\xb7\x00:\xff\xff\xff\xff\xff\xff\xff\x00\xff\xff\xff\xff\xff\xff\xff\xff\xfe\xff\xff\xff:$Q:FOC" > /proc/sys/fs/binfmt_misc/register
fi
grep -E '^interpreter' $B
grep -E '^(enabled|flags)' /proc/sys/fs/binfmt_misc/qemu-aarch64

# SWFK hmi-data images -> /var/begu/... (targets of the firmware's own symlinks)
mnt() { # image  mountpoint
  mkdir -p "$R$2"
  mountpoint -q "$R$2" || mount -o loop,ro "$SW/$1" "$R$2" && echo "mounted $1 -> $2"
}
# bmw-shared nests inside the bmw image (ro/optional_dirs.txt wants bmw/shared): make the mountpoint once
if ! mountpoint -q "$R/var/begu/hmi-data/bmw"; then
  T=$(mktemp -d); mount -o loop "$SW/swfk-0000a6b1.hmi-data.bmw.ext4" $T && mkdir -p $T/shared; umount $T; rmdir $T
fi
mnt swfk-0000a6b1.hmi-data.bmw.ext4          /var/begu/hmi-data/bmw
mnt swfk-0000a6b0.hmi-data.bmw-shared.ext4   /var/begu/hmi-data/bmw/shared
mnt swfk-0000a6b0.hmi-data.bmw-shared.ext4   /var/begu/hmi-data/bmw-shared
mnt swfk-0000a6b2.hmi-data.bmwm.ext4         /var/begu/hmi-data/bmwm
# vehicle model packs: dir names must match ro/vehicles/widgetasset/vehicles/<VARIANT> symlinks
mnt swfk-0000aed4.hmi-vehicles.g26bev.ext4   /var/begu/hmi-vehicles/G26BEV
mnt swfk-0000a691.hmi-vehicles.g80lci.ext4   /var/begu/hmi-vehicles/G80LCI

for d in proc sys dev dev/pts; do mkdir -p $R/$d; mountpoint -q $R/$d || mount --bind /$d $R/$d; done
mkdir -p $R/tmp $R/run $R/var/run/wayland $R/var/opt/public/hmi/hmi_id8main $R/var/opt/personal $R/var/begu/IBA $R/var/data/rsu-shared
chmod 1777 $R/tmp

# Runtime Variant Provider output: libcod's rvp_get_ecu_type() needs ECU (env or variant.env) -> cafd_mgu_02_l.bin
mkdir -p $R/run/etc $R/var/run/etc
printf 'ECU=MGU_02_L\nHWVAR=highf\nREV=\n' | tee $R/run/etc/variant.env > $R/var/run/etc/variant.env
# per-ECU links rvp creates at boot (from /etc/rvp-symlinks.ini [MGU_02_L])
awk '/^\[MGU_02_L\]/{f=1;next} /^\[/{f=0} f && /^\/run\//' $R/etc/rvp-symlinks.ini | while IFS='=' read -r l t; do
  mkdir -p "$R$(dirname $l)"; [ -e "$R$l" ] || ln -sfn "$t" "$R$l"
done

# Vehicle series normally arrives over the vehicle bus; with it empty, waitForOptionalDataDirs checks
# ro/vehicles/widgetasset/vehicles/{variant=""}/hmi_version. Satisfy the gate with the i4 (G26BEV) pack's version.
# Uses the profile's VARIANT (profiles/*.conf), default G26BEV.
VD=$R/opt/ivi/rootfs/usr/share/hmi/data/ro/vehicles/widgetasset/vehicles
cp $R/var/begu/hmi-vehicles/${VARIANT:-G26BEV}/hmi_version $VD/hmi_version
# 3D car: with default coding the series is "Unbekannt" and the HMI loads its built-in default,
# vehicles/G05 (an X5). Put the profile's vehicle pack in that place instead.
# The pack's per-trim folder is vehicle_<SERIES>, but the HMI asks for vehicle_G05, so build a
# link tree (chroot-absolute targets) with that alias and mount it over vehicles/G05.
V=${VARIANT:-G26BEV}; P=/var/begu/hmi-vehicles/$V; L=$R/var/emu-vehicle
while mountpoint -q $VD/G05; do umount $VD/G05; done
# Off by default: the aliased pack loads but no car renders (the HMI still derives colour/trim from
# the "unknown" series). Proper fix = real series coding. VEHICLE_ALIAS=1 to experiment.
if [ "${VEHICLE_ALIAS:-0}" = 1 ]; then
rm -rf $L; mkdir -p $L
for e in $R$P/*; do
  n=$(basename $e); [ "$n" = lost+found ] && continue
  if [[ $n == TRIM* ]]; then
    mkdir -p $L/$n
    for t in $e/*; do ln -s $P/$n/$(basename $t) $L/$n/$(basename $t); done
    [ -e $e/vehicle_$V ] && ln -sfn $P/$n/vehicle_$V $L/$n/vehicle_G05
  else
    ln -s $P/$n $L/$n
  fi
done
mount --bind $L $VD/G05 && echo "3D vehicle: $V (as default G05): $(ls $L | tr '\n' ' ')"
fi

# Hmi8 NEEDs unversioned libgbm.so; without this the loader falls back to Qualcomm's gbm -> Adreno/GSL
ML=$R/opt/mesa/usr/lib/aarch64-linux-gnu
[ -e $ML/libgbm.so ] || ln -s libgbm.so.1 $ML/libgbm.so
echo setup-ok
