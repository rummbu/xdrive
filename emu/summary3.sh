#!/bin/bash
L=/srv/mgu22/hmi.log
strip() { sed -E 's/^[0-9/:. -]+[0-9]+ [0-9]+ ECU1 //' | cut -c1-230; }
echo "lines: $(wc -l < $L)  first: $(grep -aoE '^[0-9]{4}/[0-9/]+ [0-9:.]+' $L | head -1)  last: $(grep -aoE '^[0-9]{4}/[0-9/]+ [0-9:.]+' $L | tail -1)"
echo "=== after initGalWindowConfig: next 40 meaningful lines"
grep -an 'initGalWindowConfig' $L | head -2
N=$(grep -an 'initGalWindowConfig' $L | head -1 | cut -d: -f1)
tail -n +$N $L | grep -avE 'fileExist|ColorRegistryLoader|ProfTime|tHMI_Timer|\[STAT\]|Mainloop did not|cei::|local_client_endpoint|on_disconnect|notifyAlive|isCodingFeature|LUA|offer_event|REGISTER EVENT|SUBSCRIBE|ON_AVAILABLE|Registering function|printProcStat|updateProfiling|operator\(\)' | strip | head -60
echo "=== distinct thread names active in last 2 minutes"
grep -aoE '\[\[t[A-Za-z_]+#' $L | sort | uniq -c | sort -rn | head
echo "=== tail (filtered)"
grep -avE 'tHMI_Timer|\[STAT\]|Mainloop did not|cei::|local_client|on_disconnect|ProfTime|printProcStat|updateProfiling|operator\(\)' $L | tail -20 | strip
