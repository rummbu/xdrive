#!/bin/bash
R=/srv/mgu22/root
for u in mediaapp mediaengine mediaindexer mediaddpserver waveplayer init_audio dsp-audioltd; do
  f=$(find $R -xdev -name "$u.service" 2>/dev/null | head -1)
  [ -n "$f" ] && { echo "== $u ($f)"; grep -E '^(ExecStart|User|Environment|EnvironmentFile|After|Requires)=' "$f"; }
done
echo "== audio stack in rootfs =="
ls $R/usr/bin $R/opt/ivi/rootfs/usr/bin 2>/dev/null | grep -iE 'pulse|pipewire|alsa|aplay|gst|audio|am[a-z]*d$|audiomanager' | head -20
ls $R/usr/lib/gstreamer-1.0 $R/opt/ivi/rootfs/usr/lib/gstreamer-1.0 2>/dev/null | grep -iE 'alsa|pulse|sink|qahw|qti' | head -20
ls $R/etc/asound* $R/usr/share/alsa 2>/dev/null | head
echo "== mediaengine libs =="
B=$(find $R -xdev -type f -name mediaengine 2>/dev/null | head -1); echo $B
aarch64-linux-gnu-readelf -d $B 2>/dev/null | grep NEEDED | grep -iE 'gst|alsa|pulse|audio|qahw|tinyalsa' | head
