#!/bin/bash
# sim.sh <command-file> : feed carsim's control FIFO, show its acknowledgements
N=$(grep -c . "$1")
timeout 5 sh -c "cat '$1' > /srv/mgu22/root/tmp/carsim.fifo" || echo "carsim not reading its fifo"
sleep 0.5
grep -a -E '^(ok|unknown|FIELD)' /srv/mgu22/carsim.log | tail -n "$N"
