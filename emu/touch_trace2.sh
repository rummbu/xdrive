#!/bin/bash
LOG=/srv/mgu22/hmi.log
echo "== who handled touches =="
grep -a 'CHmiTouchEventHandler::onTouchEvent\]' $LOG | sed 's/.*onTouchEvent\] //' | sort | uniq -c
echo "== mouse coords seen =="
grep -a 'mouseButtonDown' $LOG | sed 's/.*mouseButtonDown\] //' | head -12
echo "== display / early video state =="
grep -aiE 'displayAndEarlyVideo|DisplayState|display.?off|EarlyVideo|displayOn|CidDisplay|DisplayMode|screenOff' $LOG | grep -av onTouchEvent | sed 's/^.\{60\}//' | cut -c1-220 | sort | uniq -c | sort -rn | head -30
