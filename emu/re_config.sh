#!/bin/bash
H=/srv/mgu22/root/opt/ivi/rootfs/usr/bin/Hmi8
echo "== command line / env options =="
strings -n 3 $H | grep -E '^-[a-z]{1,12}=?$|^-[a-z]+=' | sort -u | head -60
echo "== config selection strings =="
strings -n 6 $H | grep -iE 'codingflags|config\.%|project config|selected config|forceconfig|HMI_CONFIG|HMI_PROJECT|eva_BMWM|getEvaFlag|evaflag' | sort -u | head -30
echo "== log lines about config selection (verbose boot) =="
grep -aiE 'codingflags|project ?config|config\.(bmw|rr)|selected|eva_' /srv/mgu22/hmi.log | cut -c95-300 | sort -u | head -20
