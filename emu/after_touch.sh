#!/bin/bash
# What happened after the last touch-up?  after_touch.sh [lines]
LOG=/srv/mgu22/hmi.log
L=$(grep -an 'Press: false' $LOG | tail -1 | cut -d: -f1)
sed -n "$((L-40)),\$p" $LOG | grep -avE 'RPER|RRND|RCLI|EventQueueStat|onCounterTimerTimeout|printCoding|CoverArt|getNoInfoString|getCurrentAudioSource|getSourceTypeOfCurrentlySelected|updateMediaInfoLabels|onPrintVersion|doPurge|vSomeIP|connect_cbk|socket|register timeout|ProfTime|readDataBinding|getUniformValue|unregisterLayoutObject|MainLoop|passGestureToWidget|CWidgetIntersector' \
  | cut -c12-27,95-330 | head -${1:-60}
