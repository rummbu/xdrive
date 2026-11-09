#!/bin/bash
# someip_events.sh <svc> : events the HMI registered + eventgroups it subscribed, from vsomeipd's log
S=$1; L=/srv/mgu22/vsomeipd.log
echo "== REGISTER EVENT lines (raw sample) =="
grep -a "$S" $L | grep -aiE 'register|REGISTER' | head -3 | cut -c95-300
echo "== SUBSCRIBE lines =="
grep -a "$S" $L | grep -aiE 'subscri' | cut -c95-300 | sort -u | head -60
