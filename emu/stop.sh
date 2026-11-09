#!/bin/bash
pkill -INT -f Hmi8; sleep 2; pkill -f Hmi8; pkill -f /usr/bin/vsomeipd; pkill -f 'rootfs/usr/bin/(persod|mediaapp|mediaengine|mediaindexer)'; pkill -f carsim_supervisor; pkill -f 'qemu-aarch64-static /opt/emu/carsim'; pkill -f 'weston.*mgu22'; echo stopped
