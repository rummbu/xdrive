#!/bin/bash
LOG=/srv/mgu22/hmi.log
D=$(grep -an 'mouseButtonDown' $LOG | tail -1 | cut -d: -f1)
U=$(grep -an 'mouseButtonUp' $LOG | tail -1 | cut -d: -f1)
echo "down line $D, up line $U"
sed -n "${D},${U}p" $LOG | grep -aE 'mouseButton|LongPress|startDrag|beginDrag|DragNDrop|long|Gesture|touch gesture|forwardTouchData|onTouchEvent\] Touch event handled \[' | cut -c1-60,95-300 | head -30
