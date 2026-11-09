/*
 * evdev ioctl shim for running the MGU22 Hmi8 under qemu-aarch64 (user mode).
 *
 * qemu-user 8.x does not translate evdev ioctls (EVIOC*): they all fail with ENOTTY, so the
 * HMI's libmtdev cannot open the CID touch panel. Reading input_events works fine, so this
 * LD_PRELOAD library answers the evdev *queries* with the capabilities of the uinput panel that
 * mgu-ivi-controller.so creates ("cid-tsc", 1920x640, 10 slots). Every other ioctl goes straight
 * to the kernel (through qemu) as before.
 *
 * Build (aarch64): aarch64-linux-gnu-gcc -shared -fPIC -O2 -nostartfiles -o libevdevshim.so evdev-shim.c
 * Use:             QEMU_SET_ENV=LD_PRELOAD=/opt/emu/libevdevshim.so
 * Keep in sync with tsc_create() in mgu-ivi-controller.c.
 */
#include <stdarg.h>
#include <errno.h>
#include <string.h>
#include <sys/syscall.h>
#include <linux/input.h>

#include <stdlib.h>
#define TSC_SLOTS 10
/* panel size follows the profile's display (MGU_TSC_W/H), default the 1920x640 CID */
static int env_int(const char *n, int d) { const char *v = getenv(n); return v && *v ? atoi(v) : d; }
#define TSC_W env_int("MGU_TSC_W", 1920)
#define TSC_H env_int("MGU_TSC_H", 640)

static long raw_ioctl(int fd, unsigned long req, void *arg)
{
	register long x0 __asm__("x0") = fd;
	register long x1 __asm__("x1") = (long)req;
	register long x2 __asm__("x2") = (long)arg;
	register long x8 __asm__("x8") = __NR_ioctl;
	__asm__ volatile("svc #0" : "+r"(x0) : "r"(x1), "r"(x2), "r"(x8) : "memory", "cc");
	return x0;
}

static int set_bits(void *buf, unsigned len, const int *bits, int n)
{
	unsigned char *b = buf;
	memset(b, 0, len);
	for (int i = 0; i < n; i++)
		if ((unsigned)bits[i] / 8 < len)
			b[bits[i] / 8] |= 1u << (bits[i] % 8);
	return (int)len;
}

static int absinfo(int code, struct input_absinfo *a)
{
	memset(a, 0, sizeof(*a));
	switch (code) {
	case ABS_X: case ABS_MT_POSITION_X: a->maximum = TSC_W - 1; return 0;
	case ABS_Y: case ABS_MT_POSITION_Y: a->maximum = TSC_H - 1; return 0;
	case ABS_MT_SLOT: a->maximum = TSC_SLOTS - 1; return 0;
	case ABS_MT_TRACKING_ID: a->maximum = 65535; return 0;
	case ABS_MT_PRESSURE: a->maximum = 255; return 0;
	}
	return -EINVAL;
}

/* returns >=0 or -errno; -ENOSYS = not an evdev query, pass through */
static int fake_evdev(unsigned long req, void *arg)
{
	unsigned nr = _IOC_NR(req), len = _IOC_SIZE(req);
	if (_IOC_TYPE(req) != 'E')
		return -ENOSYS;
	if (req == EVIOCGVERSION) { *(int *)arg = EV_VERSION; return 0; }
	if (req == EVIOCGID) {
		struct input_id *id = arg;
		id->bustype = BUS_I2C; id->vendor = 0x0bb; id->product = 0x0cd; id->version = 1;
		return 0;
	}
	if (req == EVIOCGRAB || req == EVIOCREVOKE || req == EVIOCSCLOCKID)
		return 0;
	if (_IOC_DIR(req) != _IOC_READ)
		return -ENOSYS;
	if (nr == 0x06) { /* EVIOCGNAME */
		static const char n[] = "cid-tsc";
		unsigned k = len < sizeof(n) ? len : sizeof(n);
		memcpy(arg, n, k);
		return (int)k;
	}
	if (nr == 0x07 || nr == 0x08) { /* PHYS / UNIQ: empty */
		if (len) *(char *)arg = 0;
		return len ? 1 : 0;
	}
	if (nr == 0x09) { /* EVIOCGPROP */
		static const int p[] = { INPUT_PROP_DIRECT };
		return set_bits(arg, len, p, 1);
	}
	if (nr == 0x0a) { /* EVIOCGMTSLOTS: { u32 code; s32 values[] } */
		int *v = arg;
		unsigned n = len / sizeof(int);
		for (unsigned i = 1; i < n; i++)
			v[i] = v[0] == ABS_MT_TRACKING_ID ? -1 : 0;
		return 0;
	}
	if (nr >= 0x18 && nr <= 0x1b) { /* KEY / LED / SND / SW state: nothing pressed */
		memset(arg, 0, len);
		return (int)len;
	}
	if (nr >= 0x20 && nr < 0x20 + EV_CNT) { /* EVIOCGBIT(ev) */
		static const int ev[] = { EV_SYN, EV_KEY, EV_ABS };
		static const int key[] = { BTN_TOUCH };
		static const int abs[] = { ABS_X, ABS_Y, ABS_MT_SLOT, ABS_MT_POSITION_X, ABS_MT_POSITION_Y,
					   ABS_MT_TRACKING_ID, ABS_MT_PRESSURE };
		switch (nr - 0x20) {
		case 0: return set_bits(arg, len, ev, 3);
		case EV_KEY: return set_bits(arg, len, key, 1);
		case EV_ABS: return set_bits(arg, len, abs, 7);
		default: return set_bits(arg, len, 0, 0);
		}
	}
	if (nr >= 0x40 && nr < 0x40 + ABS_CNT) /* EVIOCGABS(abs) */
		return absinfo(nr - 0x40, arg);
	return -ENOSYS;
}

int ioctl(int fd, unsigned long req, ...)
{
	va_list ap;
	va_start(ap, req);
	void *arg = va_arg(ap, void *);
	va_end(ap);
	long r = raw_ioctl(fd, req, arg);
	if (r == -ENOTTY || r == -EINVAL) {
		/* qemu refused it: answer evdev queries ourselves */
		int f = fake_evdev(req, arg);
		if (f != -ENOSYS)
			r = f;
	}
	if (r < 0 && r > -4096) {
		errno = (int)-r;
		return -1;
	}
	return (int)r;
}
