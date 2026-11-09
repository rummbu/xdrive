#!/bin/bash
# capi_last.sh <svc.id> : the most recent complete capi-trace decode of one message id
K="CAPI $1"
grep -a "^$K " /srv/mgu22/hmi.log | awk -v k="$K BEGIN" '$0 ~ k {buf=""} {buf = buf $0 "\n"} END {printf "%s", buf}'
