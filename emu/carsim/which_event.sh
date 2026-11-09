#!/bin/bash
# which_event.sh <svc> <payload> <log-regex> <ev>... : which event triggers a given HMI log line
S=$1; P=$2; RX=$3; shift 3
for ev in "$@"; do
  a=$(grep -ac "$RX" /srv/mgu22/hmi.log)
  echo "set $S 0001 $ev $P" > /srv/mgu22/root/tmp/carsim.fifo
  sleep 3
  b=$(grep -ac "$RX" /srv/mgu22/hmi.log)
  echo "$ev: +$((b-a))"
done
