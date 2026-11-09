#!/bin/bash
# Where did the logged touch events come from?
LOG=/srv/mgu22/hmi.log
grep -an 'forwardTouchData\] Touch data' $LOG | cut -c1-160 | head -20
echo "count: $(grep -ac 'forwardTouchData\] Touch data' $LOG)"
echo "== context before first touch =="
L=$(grep -an 'forwardTouchData' $LOG | head -1 | cut -d: -f1)
sed -n "$((L-25)),$((L+2))p" $LOG | cut -c1-230
echo "== touch device setup lines =="
grep -aiE 'touchscreen|wl_touch|wl_pointer|event1|mtdev|HMI_TOUCH|input device' $LOG | grep -avE 'forwardTouch|onTouch|ResourceData|printCoding|LOG CONFIG' | cut -c1-230 | head -25
echo "== weston tail =="; tail -5 /srv/mgu22/weston.log
