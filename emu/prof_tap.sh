#!/bin/bash
# Profile threads while a tap triggers a screen transition. prof_tap.sh X Y [seconds]
SRC="$(cat /srv/mgu22/repo_root)/emu"
( sleep 0.3; echo "tap ${1:-960} ${2:-596}" > /srv/mgu22/input.fifo ) &
tr -d '\r' < "$SRC/prof_threads.sh" | bash -s ${3:-6} 2>/dev/null
