#!/bin/bash
# value_sweep.sh <svc> <inst> <event> <log-regex> <payload>... : push each payload, show the
# HMI log lines matching <log-regex> that appear right after it
S=$1; I=$2; E=$3; RX=$4; shift 4
FIFO=/srv/mgu22/root/tmp/carsim.fifo
for p in "$@"; do
  N=$(wc -l < /srv/mgu22/hmi.log)
  echo "set $S $I $E $p" > $FIFO
  sleep 2.5
  echo "$p => $(tail -n +$N /srv/mgu22/hmi.log | grep -aoE "$RX" | sort -u | tr '\n' ' ')"
done
