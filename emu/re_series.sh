#!/bin/bash
R=/srv/mgu22/root
H=$R/opt/ivi/rootfs/usr/bin/Hmi8
echo "== libcod / coding imports of Hmi8 =="
aarch64-linux-gnu-nm -D --undefined-only $H | grep -iE ' cod_|coding|rvp_' | head -20
L=$(find $R -xdev -name 'libcod.so*' | head -1); echo "lib: $L"
aarch64-linux-gnu-nm -D --defined-only $L | grep ' T ' | head -40
echo "== CSeriesToFolder =="
aarch64-linux-gnu-nm -DC $H | grep -E 'CSeriesToFolder|SeriesToFolder' | head
echo "== 'Unbekannt' + series coding strings =="
strings -n 6 $H | grep -iE 'Unbekannt|series coding|BAUREIHE|va_BR_|eva_BR|TYP_BAUREIHE' | sort -u | head -20
grep -c . $R/opt/ivi/rootfs/usr/share/hmi/data/ro/MGU22_Coding.txt; grep -iE 'baureihe|series|BR_' $R/opt/ivi/rootfs/usr/share/hmi/data/ro/MGU22_Coding.txt | head -20
