#!/bin/bash
# Wire the chroot's ALSA/PulseAudio clients to WSLg's PulseAudio server (Windows speakers).
R=/srv/mgu22/root
SRC="$(cat /srv/mgu22/repo_root)/emu/audio"
tr -d '\r' < "$SRC/asound.conf" > $R/etc/asound.conf
mkdir -p $R/run/pulse-wslg
touch $R/run/pulse-wslg/native 2>/dev/null
mountpoint -q $R/run/pulse-wslg/native || mount --bind /mnt/wslg/PulseServer $R/run/pulse-wslg/native
chmod 777 $R/run/pulse-wslg
# tone test tool
if [ "$SRC/tone.c" -nt $R/opt/emu/tone ] || [ ! -x $R/opt/emu/tone ]; then
  tr -d '\r' < "$SRC/tone.c" > /srv/mgu22/tone.c
  aarch64-linux-gnu-gcc -O2 -o $R/opt/emu/tone /srv/mgu22/tone.c -lm \
    -L$R/opt/ext/rootfs/usr/lib -Wl,-rpath-link,$R/opt/ext/rootfs/usr/lib -Wl,-rpath-link,$R/usr/lib -l:libasound.so.2
fi
echo "audio: HarmanX:* -> pulse -> unix:/run/pulse-wslg/native"
