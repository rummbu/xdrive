#!/bin/bash
# Where does the HMI get touch from?
R=/srv/mgu22/root
H=$R/opt/ivi/rootfs/usr/bin/Hmi8
echo "== kernel uinput =="; ls -l /dev/uinput 2>&1; grep -i uinput /proc/modules 2>/dev/null; zcat /proc/config.gz 2>/dev/null | grep -E 'INPUT_UINPUT|INPUT_EVDEV'
echo "== Hmi8 strings =="
strings -n 6 $H | grep -iE 'touch_input|TOUCH_INPUT|/dev/input|evdev|libinput|mtdev|tslib|EVIOC|cid-touch|HMI_.*INPUT|touchscreen' | sort -u | head -60
echo "== NEEDED input libs =="
aarch64-linux-gnu-readelf -d $H 2>/dev/null | grep -iE 'input|mtdev|evdev|udev|ts' || readelf -d $H | grep -iE 'input|mtdev|evdev|udev|ts'
echo "== libs mentioning cid-touchscreen / HMI_TOUCH =="
grep -rlsE 'HMI_TOUCH_INPUT_DEVICE|cid-touchscreen' $R/opt/ivi/rootfs/usr/lib $R/opt/ivi/rootfs/usr/bin $R/etc $R/opt/ivi/rootfs/etc $R/lib/udev $R/usr/lib 2>/dev/null | head -20
echo "== env/unit files =="
grep -rsE 'TOUCH|INPUT_DEVICE' $R/etc/systemd $R/lib/systemd $R/opt/ivi/rootfs/etc $R/opt/ivi/rootfs/lib/systemd 2>/dev/null | head -30
echo "== udev rules for touchscreen =="
grep -rsE 'touchscreen|cid-touch' $R/etc/udev $R/lib/udev $R/usr/lib/udev 2>/dev/null | head -20
