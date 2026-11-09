#!/bin/bash
# Which backend services does the HMI wait for, and does the dump contain their providers?
R=/srv/mgu22/root
echo "== stub (provider) libraries present in the dump, by area =="
find $R -xdev -name 'libde.bmw.*stub.someip.so*' 2>/dev/null | sed 's/.*libde\.bmw\.infotainment\.//; s/\.stub\.someip.*//' | sort -u \
  | grep -iE 'climate|hvac|perso|profile|user|audio|media|player|bluetooth|bt|phone|tuner|vehicle|kombi|cluster|ic\.|hud' | head -40
echo "== total stub libs: $(find $R -xdev -name '*stub.someip.so*' 2>/dev/null | wc -l)"
echo "== executables that link climate / personalization / audio / bluetooth stubs =="
for b in $(find $R/usr/bin $R/opt/ivi/rootfs/usr/bin $R/opt/ext/rootfs/usr/bin -xdev -type f -size +50k 2>/dev/null); do
  n=$(aarch64-linux-gnu-readelf -d "$b" 2>/dev/null | grep -oE 'libde\.bmw\.[a-z.]*(climate|personali|audio|bluetooth|mediaplayer|phone)[a-z.]*stub' | sort -u | tr '\n' ' ')
  [ -n "$n" ] && echo "$(basename $b): $n"
done | head -25
echo "== systemd units (service names) mentioning audio/bt/climate/perso/kombi =="
ls $R/lib/systemd/system $R/etc/systemd/system $R/opt/ivi/rootfs/lib/systemd/system $R/opt/ivi/rootfs/etc/systemd/system 2>/dev/null \
  | grep -iE 'audio|blue|bt|climate|perso|user|kombi|cluster|media|pulse|pipewire|ame|player' | sort -u | head -30
echo "== vehicles in dump =="; ls $R/var/begu/hmi-vehicles/ /srv/mgu22/swfk 2>/dev/null
