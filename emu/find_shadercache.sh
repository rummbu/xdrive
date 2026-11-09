#!/bin/bash
R=/srv/mgu22/root
strings -n 8 $R/opt/ivi/rootfs/usr/bin/Hmi8 | grep -iE 'shadercache|shader_cache|binaryshader|\.shc|shaders/' | grep '/' | sort -u | head -10
echo "== recently written files in rootfs (not logs) =="
find $R/var $R/opt/ivi/rootfs/var $R/tmp $R/home 2>/dev/null -xdev -type f -mmin -400 -size +20k | grep -viE '\.log$' | head -20
du -sh $(find $R -xdev -type d -iname '*shader*' 2>/dev/null | head -5) 2>/dev/null
