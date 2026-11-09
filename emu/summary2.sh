#!/bin/bash
L=/srv/mgu22/hmi.log
strip() { sed -E 's/^[0-9/:. -]+[0-9]+ [0-9]+ ECU1 //' | awk '!s[$0]++' | cut -c1-220; }
echo "=== weston (this run)"; grep -E 'mgu-ivi|surface|error' /srv/mgu22/weston.log | tail -8
echo "=== window / ramses / display / egl / wayland"
grep -aiE 'generateWindow|window info|ramses|egl|wayland|ivi_|surface|displayconfig|display_3to1|resolution|renderer|swapchain|framebuffer' $L | grep -avE 'Registering function|REGISTER|offer_event|^\[-|LUA|loadScripts' | strip | head -40
echo "=== progress markers (ProfTime / startup / loaded)"
grep -aE 'ProfTime1\]|loaded [0-9]+ widgets|STARTUP|startup|Startup' $L | strip | tail -25
echo "=== last timestamp"; grep -aoE '^[0-9]{4}/[0-9/]+ [0-9:.]+' $L | tail -1
