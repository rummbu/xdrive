#!/bin/bash
L=/srv/mgu22/hmi.log
echo "=== weston mgu-ivi (this run)"; awk '/controller ready/{buf=""} {buf=buf"\n"$0} END{print buf}' /srv/mgu22/weston.log | grep -E 'mgu-ivi|error|EGL|fail' | head -40
echo "=== renderer display lifecycle"
grep -a 'RRND log' $L | grep -aiE 'CreateDisplay|DisplayCreate|ivi_controller|system compositor|SystemCompositor|EGL|egl|Window_Wayland|wl_|surface|display 0|Display 0|failed|error|framebuffer|swap|mapped|Rendered|SceneMapped|state Rendered|state Mapped' \
  | grep -avE 'Map scene with id|Failed to map scene|sceneMapped failed|initiating mapping' | sed -E 's/^.*RRND log //' | awk '!s[$0]++' | head -60
echo "=== scene states reached"
grep -aoE 'scene [A-Za-z_0-9]+ is in state [A-Za-z]+' $L | sort | uniq -c | sort -rn | head -20
echo "=== last timestamp: $(grep -aoE '^[0-9]{4}/[0-9/]+ [0-9:.]+' $L | tail -1)"
