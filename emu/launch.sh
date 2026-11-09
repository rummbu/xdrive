#!/bin/bash
# Sync emulator scripts into WSL, build the compositor module, run Hmi8 in the FOREGROUND.
# (WSL stops the distro when no wsl.exe session is attached, so start.ps1 keeps this one alive.)
#   launch.sh [seconds]   (0/omitted = run until stop)
SRC="$(cd "$(dirname "$0")" && pwd)"
# every other WSL-side script finds the repo through this file
mkdir -p /srv/mgu22 && printf '%s' "${SRC%/emu}" > /srv/mgu22/repo_root
for f in setup.sh run_hmi.sh build_ctl.sh mgu-ivi-controller.c; do tr -d '\r' < "$SRC/$f" > /srv/mgu22/$f; done
bash /srv/mgu22/build_ctl.sh >/srv/mgu22/build_ctl.log 2>&1 || { echo "controller build failed"; cat /srv/mgu22/build_ctl.log; exit 1; }
tr -d '\r' < "$SRC/build_shim.sh" | bash >/srv/mgu22/build_shim.log 2>&1 || { echo "evdev shim build failed"; cat /srv/mgu22/build_shim.log; exit 1; }
if [ ! -x /srv/mgu22/root/opt/emu/carsim ] || [ "$SRC/carsim/carsim.cpp" -nt /srv/mgu22/root/opt/emu/carsim ]; then
  tr -d '\r' < "$SRC/carsim/build.sh" | bash >/srv/mgu22/build_carsim.log 2>&1 || { echo "carsim build failed"; cat /srv/mgu22/build_carsim.log; exit 1; }
fi
pkill -INT -f Hmi8 2>/dev/null; sleep 1; pkill -f Hmi8; pkill -f /usr/bin/vsomeipd; pkill -f 'weston.*mgu22'; sleep 0.5
# byte patches so Hmi8 accepts input without the car's display manager (backup kept as Hmi8.orig)
python3 -I "$SRC/patch_hmi.py" /srv/mgu22/root/opt/ivi/rootfs/usr/bin/Hmi8 || exit 1
: > /srv/mgu22/weston.log
# profile (profiles/<name>.conf): BRAND + VARIANT for this iDrive setup
PROFILE=${3:-xdrive}
PF="$SRC/profiles/$PROFILE.conf"
[ -f "$PF" ] || { echo "unknown profile '$PROFILE'"; ls "$SRC/profiles"; exit 1; }
set -a; . <(tr -d '\r' < "$PF"); set +a
echo "$PROFILE" > /srv/mgu22/profile
# car coding (libcod NCD data): coding/<profile>.txt overrides on the HMI's template coding;
# no file = no NCD = the HMI's "default coding" mode
R=/srv/mgu22/root
rm -f $R/var/ncd/area_*.bin
if [ -f "$SRC/coding/$PROFILE.txt" ]; then
  python3 -I "$SRC/gen_coding.py" $R/usr/share/sysfunc/coding/cafd_mgu_02_l.bin \
    $R/opt/ivi/rootfs/usr/share/hmi/data/ro/MGU22_Coding.txt "$SRC/coding/$PROFILE.txt" $R/var/ncd \
    > /srv/mgu22/coding.log 2>&1 || { echo "coding failed"; cat /srv/mgu22/coding.log; exit 1; }
fi
HMI_TIMEOUT=${1:-0} DLT_LEVEL=${2:-::3} exec bash /srv/mgu22/run_hmi.sh > /srv/mgu22/run.log 2>&1
