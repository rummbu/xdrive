#!/bin/bash
R=/srv/mgu22/root
find $R -xdev -iname '*kombi*' 2>/dev/null | head -20
echo "== wants =="
for d in $(find $R -xdev -type d -name 'container-kombi.service.wants' 2>/dev/null); do echo "$d:"; ls $d; done
echo "== lxc configs =="
find $R -xdev -path '*lxc*' -name 'config' 2>/dev/null | head
ls $R/var/lib/lxc $R/opt 2>/dev/null
