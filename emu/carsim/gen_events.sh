#!/bin/bash
# gen_events.sh <svc> <inst> <probe-hex> : carsim 'event'+'set' lines for every event the HMI
# subscribed to (from carsim's vsomeip log: SUBSCRIBE ... [svc.inst.eventgroup:event:major])
S=$1; I=$2; P=${3:-0000001001010101010101010101010101010101}
grep -aoE "\[$S\.$I\.[0-9a-f]{4}:[0-9a-f]{4}:" /srv/mgu22/carsim.log | sort -u | while IFS=. read -r _ _ rest; do
  eg=${rest%%:*}; ev=${rest#*:}; ev=${ev%:}
  echo "event $S $I $ev $eg"
  echo "set $S $I $ev $P"
done
