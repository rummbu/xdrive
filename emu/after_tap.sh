#!/bin/bash
# What did the HMI do after the last tap?  after_tap.sh [lines]
LOG=/srv/mgu22/hmi.log
L=$(grep -an 'mouseButtonUp' $LOG | tail -1 | cut -d: -f1)
sed -n "$L,\$p" $LOG | grep -avE 'RPER|EventQueueStat|onCounterTimerTimeout|printCoding|CoverArt|getNoInfoString|getCurrentAudioSource|getSourceTypeOfCurrentlySelected|updateMediaInfoLabels|onPrintVersion|doPurge|forwardTouchData|onTouchInput|onTouchInteraction|CHmiTouchEventHandler|Touch event handled|onCIDActivity|vSomeIP Security' \
  | cut -c27-260 | head -${1:-60}
