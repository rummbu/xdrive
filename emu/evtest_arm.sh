#!/bin/bash
# Do evdev ioctls work for an aarch64 guest under qemu-user?
which aarch64-linux-gnu-gcc || apt-get install -y -qq gcc-aarch64-linux-gnu >/dev/null 2>&1
mkdir -p /srv/mgu22/root/tmp
cat > /tmp/evt.c <<'EOF'
#include <stdio.h>
#include <fcntl.h>
#include <errno.h>
#include <string.h>
#include <sys/ioctl.h>
#include <linux/input.h>
int main(int c, char **v) {
	int fd = open(v[1], O_RDONLY);
	printf("open %d errno=%s\n", fd, strerror(errno));
	unsigned long bits[(ABS_MAX + 64) / 64] = {0};
	int r = ioctl(fd, EVIOCGBIT(EV_ABS, sizeof(bits)), bits);
	printf("EVIOCGBIT(EV_ABS) = %d errno=%s bits0=%lx\n", r, r < 0 ? strerror(errno) : "-", bits[0]);
	struct input_absinfo ai;
	r = ioctl(fd, EVIOCGABS(ABS_MT_POSITION_X), &ai);
	printf("EVIOCGABS(MT_X) = %d errno=%s max=%d\n", r, r < 0 ? strerror(errno) : "-", ai.maximum);
	char name[64] = "";
	r = ioctl(fd, EVIOCGNAME(sizeof(name)), name);
	printf("EVIOCGNAME = %d '%s'\n", r, name);
	r = ioctl(fd, EVIOCGRAB, 1);
	printf("EVIOCGRAB = %d errno=%s\n", r, r < 0 ? strerror(errno) : "-");
	return 0;
}
EOF
aarch64-linux-gnu-gcc -static -O1 -o /srv/mgu22/root/tmp/evt /tmp/evt.c && \
QEMU_STRACE= chroot /srv/mgu22/root /tmp/evt /dev/input/cid-touchscreen
qemu-aarch64-static --version | head -1
