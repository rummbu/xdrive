#!/bin/bash
R=/srv/mgu22/root
H=$R/opt/ivi/rootfs/usr/bin/Hmi8
echo "== source files under */simulation/* or *simul* =="
strings -n 10 $H | grep -E '^/usr/src/debug/hmi/.*/(simulation|hmisimulation|sim)/' | sed 's#.*/git/##' | sort -u | head -40
echo "== demangled symbols with Simulation =="
aarch64-linux-gnu-nm -DC $H | grep -iE 'simulation' | grep -viE 'route|nav|speech|DLGSTATE' | awk '{$1="";$2="";print}' | sort -u | head -50
echo "== SimulationExchange interface =="
strings -n 4 $R/opt/ivi/rootfs/usr/lib/libSimulationExchange.stub.dbus.so.3.2.3-2 | grep -iE 'simulation|^[a-z][A-Za-z]{4,}$' | sort -u | head -40
