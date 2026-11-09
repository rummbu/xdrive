#!/bin/bash
# event_sweep.sh <svc> <inst> <class-regex> : push each subscribed event alone and report which
# HMI handler logs right after it (needs a verbose HMI log). Uses the current field value
# (re-sent unchanged) so nothing in the UI is disturbed.
S=$1; I=$2; RX=${3:-DevClimateMaster::on}
FIFO=/srv/mgu22/root/tmp/carsim.fifo
for ev in $(grep -aoE "\[$S\.$I\.[0-9a-f]{4}:[0-9a-f]{4}:" /srv/mgu22/carsim.log | cut -d: -f2 | sort -u); do
  val=$(grep -aE "^(set|ok: set) $S $I $ev " /srv/mgu22/root/opt/emu/carsim.conf | tail -1 | cut -d' ' -f5- | tr -d ' ')
  [ -z "$val" ] && val=00000000
  N=$(wc -l < /srv/mgu22/hmi.log)
  echo "set $S $I $ev $val" > $FIFO
  sleep 2.5
  h=$(tail -n +$N /srv/mgu22/hmi.log | grep -aoE "$RX[A-Za-z0-9_]*" | sort -u | tr '\n' ' ')
  echo "$ev  ${h:-<no handler log>}"
done
