#!/bin/bash
# Restart only the car simulator with the current carsim.conf: carsim_supervisor (started by
# run_hmi.sh) re-copies the config and relaunches it; the HMI re-polls when services come back.
pkill -f 'qemu-aarch64-static /opt/emu/carsim'
echo "carsim restarting (supervisor)"
