#!/bin/bash
# Start the media stack and report health after a while (all in one wsl call: transient wsl
# sessions kill their children when they end).   test_media.sh [seconds]
SRC="$(cat /srv/mgu22/repo_root)/emu/audio"
tr -d '\r' < "$SRC/run_media.sh" | bash -s /srv/mgu22/root cortex-a76
sleep ${1:-40}
for s in mediaengine mediaindexer mediaapp; do
  if pgrep -f "rootfs/usr/bin/$s " >/dev/null; then st=RUNNING; else st=DEAD; fi
  echo "== $s $st"
  grep -aiE 'error|fail|fatal|cannot|abort|not found' /srv/mgu22/svc-$s.log | grep -avE 'vSomeIP|DLT\[|socket' | cut -c1-28,60-230 | sort -u | head -8
  tail -2 /srv/mgu22/svc-$s.log | cut -c1-220
done
