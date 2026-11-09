#!/bin/bash
LOG=/srv/mgu22/hmi.log
D=$(grep -an 'mouseButtonDown' $LOG | tail -1 | cut -d: -f1)
sed -n "${D},\$p" $LOG | grep -aE 'gesture: (tap|longPress|drag)[^)]*state: (end|start|cancel)|pressed: false|longPressed: true|LongPress: true|DragNDrop|startDrag|onLongPress|launch|Launch|activat|Activat|error|warn' \
  | grep -avE 'vSomeIP|HSCT|getNoInfoString|CoverArt' | cut -c12-27,95-330 | head -40
