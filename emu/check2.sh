#!/bin/bash
R=/srv/mgu22/root
mount | grep -c /srv/mgu22/root
ls -la $R/dev/urandom $R/dev/random 2>&1
ls -la $R/dev | head -5
chroot $R /bin/busybox head -c 8 /dev/urandom | od -An -tx1
