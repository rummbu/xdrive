#!/bin/bash
# Fetch the ivi-controller protocol XML that RAMSES v27 builds against.
set -e
cd /srv/mgu22
command -v git >/dev/null || DEBIAN_FRONTEND=noninteractive apt-get install -y -qq git >/dev/null
command -v wayland-scanner >/dev/null || DEBIAN_FRONTEND=noninteractive apt-get install -y -qq libwayland-bin >/dev/null
T=$(git ls-remote --tags https://github.com/COVESA/ramses.git | grep -oE 'refs/tags/v?27\.0\.[0-9]+$' | sed 's#refs/tags/##' | sort -V | tail -1)
echo "ramses tag: $T"
rm -rf ramses-src
git clone -q --depth 1 --filter=blob:none --sparse --branch "$T" https://github.com/COVESA/ramses.git ramses-src
cd ramses-src
git sparse-checkout set --no-cone '*ivi*.xml' '**/ivi*.xml' >/dev/null
find . -iname '*ivi*.xml' | head
