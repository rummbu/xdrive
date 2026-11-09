#!/bin/bash
P=$(pgrep -f 'qemu-aarch64-static /opt/ivi/rootfs/usr/bin/Hmi8' | head -1)
echo "hmi pid $P"
ls -l /proc/$P/fd 2>/dev/null | grep -E 'input|event'
echo "== events on the panel during a tap =="
python3 - <<'EOF' &
import struct, os, select, time
fd = os.open("/dev/input/event0", os.O_RDONLY | os.O_NONBLOCK)
end = time.time() + 3
while time.time() < end:
    r, _, _ = select.select([fd], [], [], 0.2)
    if r:
        data = os.read(fd, 24 * 64)
        for i in range(0, len(data), 24):
            s, us, t, c, v = struct.unpack("qqHHi", data[i:i+24])
            print(f"{s}.{us:06d} type={t} code={c:#x} value={v}")
EOF
sleep 0.5
echo 'tap 960 596' > /srv/mgu22/input.fifo
wait
grep mgu-ivi /srv/mgu22/weston.log | tail -2
