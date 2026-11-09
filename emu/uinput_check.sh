#!/bin/bash
findmnt -no FSTYPE /dev
modprobe uinput; echo "modprobe=$?"
lsmod | grep -i uinput
ls -la /dev/uinput
python3 - <<'EOF'
import os, fcntl, struct, time, glob
fd = os.open("/dev/uinput", os.O_WRONLY | os.O_NONBLOCK)
UI_SET_EVBIT, UI_SET_KEYBIT, UI_DEV_CREATE, UI_DEV_DESTROY = 0x40045564, 0x40045565, 0x5501, 0x5502
fcntl.ioctl(fd, UI_SET_EVBIT, 1)        # EV_KEY
fcntl.ioctl(fd, UI_SET_KEYBIT, 0x14a)   # BTN_TOUCH
name = b"probe-tsc".ljust(80, b"\0")
os.write(fd, name + struct.pack("<HHHHI", 3, 1, 1, 1, 0) + b"\0" * (4 * 64 * 4))
fcntl.ioctl(fd, UI_DEV_CREATE)
time.sleep(0.5)
print("devices:", glob.glob("/dev/input/*"))
print([l for l in open("/proc/bus/input/devices").read().split("\n\n") if "probe-tsc" in l])
fcntl.ioctl(fd, UI_DEV_DESTROY)
EOF
