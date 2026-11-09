#!/bin/bash
L=$(pkg-config --variable=libdir libweston-13)
I=$(pkg-config --variable=includedir libweston-13)
echo "lib=$L inc=$I"
nm -D $L/libweston-13.so.0 | grep -E ' notify_(motion_absolute|button|pointer_frame)'
ls $I/libweston-13/libweston/
grep -n 'notify_motion_absolute\|^notify_button\|notify_pointer_frame' -r $I/libweston-13/ | head
