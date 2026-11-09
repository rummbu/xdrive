#!/bin/bash
set -e
cd /srv/mgu22/ramses-src
git sparse-checkout disable >/dev/null 2>&1 || true
git checkout -q HEAD -- . 2>/dev/null || true
grep -rIl --include='*.txt' --include='*.cmake' --include='*.gitmodules' -iE 'ivi-extension|ivi_controller|ivi-controller' . | head
cat .gitmodules 2>/dev/null | grep -A2 -i ivi
grep -rIn -iE 'ivi-controller|ivi_controller.*xml|wayland-ivi-extension' --include='*.txt' --include='*.cmake' . | head -15
find . -path ./.git -prune -o -iname '*controller*.xml' -print | head
