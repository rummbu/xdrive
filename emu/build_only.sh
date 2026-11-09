#!/bin/bash
# Sync + compile the compositor module without (re)starting anything.
SRC="$(cat /srv/mgu22/repo_root)/emu"
for f in build_ctl.sh mgu-ivi-controller.c; do tr -d '\r' < "$SRC/$f" > /srv/mgu22/$f; done
bash /srv/mgu22/build_ctl.sh && echo BUILD_OK
