/*
 * capi-trace: LD_PRELOAD shim (aarch64) that logs how CommonAPI-SomeIP deserializes messages, to
 * recover the exact wire format of BMW interfaces from the HMI's own (stripped) proxy code.
 *
 * Generated proxies decode payloads with a few exported primitives of libCommonAPI-SomeIP
 * (readValue(float&), readValue(uint8&, IntegerDeployment*), length fields readValue(uint32&,
 * width, signed), strings, _readRaw). We interpose them, remember service/method from the
 * InputStream constructor, and print each primitive read as it happens:
 *   CAPI b09a.0049 len w=4 -> 0
 *   CAPI b09a.0049 u8 bits=8 -> 3
 * Env: CAPI_TRACE_SVC=b09a,b510 (hex service ids to log; unset = log nothing)
 * Build: aarch64-linux-gnu-gcc -shared -fPIC -O2 -o libcapitrace.so capi-trace.c -ldl
 */
#define _GNU_SOURCE
#include <dlfcn.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static __thread uint16_t cur_svc, cur_m;
static __thread int cur_on;
static uint16_t want[64];
static int nwant = -1;

static void load_filter(void)
{
	if (nwant >= 0) return;
	nwant = 0;
	const char *e = getenv("CAPI_TRACE_SVC");
	/* hand-rolled hex: strtoul would bind to glibc 2.38's __isoc23_strtoul (firmware has 2.35) */
	while (e && *e && nwant < 64) {
		unsigned v = 0; int d;
		while ((d = (*e >= '0' && *e <= '9') ? *e - '0' : (*e >= 'a' && *e <= 'f') ? *e - 'a' + 10
		           : (*e >= 'A' && *e <= 'F') ? *e - 'A' + 10 : -1) >= 0) { v = v * 16 + d; e++; }
		want[nwant++] = (uint16_t)v;
		if (!*e) break;
		e++;  /* skip the separator (',' ':' ' ' or anything non-hex) */
	}
}

#define REAL(name, type) \
	typedef __typeof__(type) real_fn_t; \
	static real_fn_t real; \
	if (!real) real = (real_fn_t)dlsym(RTLD_NEXT, name)

/* every hooked read also reports InputStream::hasError() so the failing field is visible */
static __thread void *cur_self;
static int stream_err(void)
{
	typedef int (*he_t)(const void *);
	static he_t he;
	if (!he) he = (he_t)dlsym(RTLD_NEXT, "_ZNK9CommonAPI6SomeIP11InputStream8hasErrorEv");
	return cur_self && he ? he(cur_self) & 1 : 0;
}
#define LOG(...) do { if (cur_on) { fprintf(stderr, "CAPI %04x.%04x ", cur_svc, cur_m); \
	fprintf(stderr, __VA_ARGS__); if (stream_err()) fputs("  <ERROR>", stderr); fputc('\n', stderr); } } while (0)

/* InputStream::InputStream(Message const&, bool) */
void _ZN9CommonAPI6SomeIP11InputStreamC1ERKNS0_7MessageEb(void *self, const void *msg, int le)
{
	REAL("_ZN9CommonAPI6SomeIP11InputStreamC1ERKNS0_7MessageEb", void (*)(void *, const void *, int));
	typedef uint16_t (*getter)(const void *);
	static getter gsvc, gm;
	if (!gsvc) {
		gsvc = (getter)dlsym(RTLD_NEXT, "_ZNK9CommonAPI6SomeIP7Message12getServiceIdEv");
		gm = (getter)dlsym(RTLD_NEXT, "_ZNK9CommonAPI6SomeIP7Message11getMethodIdEv");
	}
	load_filter();
	cur_svc = gsvc ? gsvc(msg) : 0;
	cur_m = gm ? gm(msg) : 0;
	cur_on = 0;
	for (int i = 0; i < nwant; i++) if (want[i] == cur_svc) cur_on = 1;
	LOG("BEGIN le=%d", le);
	real(self, msg, le);
}

#define HOOK_INT(mangled, ctype, label, fmt, hasdepl) \
void *mangled(void *self, ctype *v, const uint8_t *depl) \
{ \
	REAL(#mangled, void *(*)(void *, ctype *, const uint8_t *)); \
	cur_self = self; void *r = real(self, v, depl); \
	if (hasdepl && depl) LOG(label " bits=%u -> " fmt, depl[0], *v); else LOG(label " -> " fmt, *v); \
	return r; \
}

HOOK_INT(_ZN9CommonAPI6SomeIP11InputStream9readValueERhPKNS0_17IntegerDeploymentIhEE, uint8_t, "u8", "%u", 1)
HOOK_INT(_ZN9CommonAPI6SomeIP11InputStream9readValueERhPKNS_15EmptyDeploymentE, uint8_t, "u8", "%u", 0)
HOOK_INT(_ZN9CommonAPI6SomeIP11InputStream9readValueERaPKNS0_17IntegerDeploymentIaEE, int8_t, "i8", "%d", 1)
HOOK_INT(_ZN9CommonAPI6SomeIP11InputStream9readValueERaPKNS_15EmptyDeploymentE, int8_t, "i8", "%d", 0)
HOOK_INT(_ZN9CommonAPI6SomeIP11InputStream9readValueERtPKNS0_17IntegerDeploymentItEE, uint16_t, "u16", "%u", 1)
HOOK_INT(_ZN9CommonAPI6SomeIP11InputStream9readValueERtPKNS_15EmptyDeploymentE, uint16_t, "u16", "%u", 0)
HOOK_INT(_ZN9CommonAPI6SomeIP11InputStream9readValueERsPKNS0_17IntegerDeploymentIsEE, int16_t, "i16", "%d", 1)
HOOK_INT(_ZN9CommonAPI6SomeIP11InputStream9readValueERsPKNS_15EmptyDeploymentE, int16_t, "i16", "%d", 0)
HOOK_INT(_ZN9CommonAPI6SomeIP11InputStream9readValueERjPKNS0_17IntegerDeploymentIjEE, uint32_t, "u32", "%u", 1)
HOOK_INT(_ZN9CommonAPI6SomeIP11InputStream9readValueERjPKNS_15EmptyDeploymentE, uint32_t, "u32", "%u", 0)
HOOK_INT(_ZN9CommonAPI6SomeIP11InputStream9readValueERiPKNS0_17IntegerDeploymentIiEE, int32_t, "i32", "%d", 1)
HOOK_INT(_ZN9CommonAPI6SomeIP11InputStream9readValueERiPKNS_15EmptyDeploymentE, int32_t, "i32", "%d", 0)
HOOK_INT(_ZN9CommonAPI6SomeIP11InputStream9readValueERmPKNS0_17IntegerDeploymentImEE, uint64_t, "u64", "%lu", 1)
HOOK_INT(_ZN9CommonAPI6SomeIP11InputStream9readValueERmPKNS_15EmptyDeploymentE, uint64_t, "u64", "%lu", 0)
HOOK_INT(_ZN9CommonAPI6SomeIP11InputStream9readValueERlPKNS0_17IntegerDeploymentIlEE, int64_t, "i64", "%ld", 1)
HOOK_INT(_ZN9CommonAPI6SomeIP11InputStream9readValueERlPKNS_15EmptyDeploymentE, int64_t, "i64", "%ld", 0)

void *_ZN9CommonAPI6SomeIP11InputStream9readValueERbPKNS_15EmptyDeploymentE(void *self, uint8_t *v, const void *d)
{
	REAL("_ZN9CommonAPI6SomeIP11InputStream9readValueERbPKNS_15EmptyDeploymentE", void *(*)(void *, uint8_t *, const void *));
	cur_self = self; void *r = real(self, v, d); LOG("bool -> %u", *v); return r;
}
void *_ZN9CommonAPI6SomeIP11InputStream9readValueERfPKNS_15EmptyDeploymentE(void *self, float *v, const void *d)
{
	REAL("_ZN9CommonAPI6SomeIP11InputStream9readValueERfPKNS_15EmptyDeploymentE", void *(*)(void *, float *, const void *));
	cur_self = self; void *r = real(self, v, d); LOG("float -> %g", *v); return r;
}
void *_ZN9CommonAPI6SomeIP11InputStream9readValueERdPKNS_15EmptyDeploymentE(void *self, double *v, const void *d)
{
	REAL("_ZN9CommonAPI6SomeIP11InputStream9readValueERdPKNS_15EmptyDeploymentE", void *(*)(void *, double *, const void *));
	cur_self = self; void *r = real(self, v, d); LOG("double -> %g", *v); return r;
}
/* length / struct-length / union-type fields: readValue(uint32&, width, isSigned) */
void *_ZN9CommonAPI6SomeIP11InputStream9readValueERjRKhRKb(void *self, uint32_t *v, const uint8_t *w, const uint8_t *s)
{
	REAL("_ZN9CommonAPI6SomeIP11InputStream9readValueERjRKhRKb", void *(*)(void *, uint32_t *, const uint8_t *, const uint8_t *));
	cur_self = self; void *r = real(self, v, w, s); LOG("len w=%u -> %u", *w, *v); return r;
}
void *_ZN9CommonAPI6SomeIP11InputStream9readValueERNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEEPKNS0_16StringDeploymentE(void *self, void *v, const void *d)
{
	REAL("_ZN9CommonAPI6SomeIP11InputStream9readValueERNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEEPKNS0_16StringDeploymentE", void *(*)(void *, void *, const void *));
	cur_self = self; void *r = real(self, v, d); LOG("string(depl)"); return r;
}
void *_ZN9CommonAPI6SomeIP11InputStream9readValueERNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEEPKNS_15EmptyDeploymentE(void *self, void *v, const void *d)
{
	REAL("_ZN9CommonAPI6SomeIP11InputStream9readValueERNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEEPKNS_15EmptyDeploymentE", void *(*)(void *, void *, const void *));
	cur_self = self; void *r = real(self, v, d); LOG("string"); return r;
}
void *_ZN9CommonAPI6SomeIP11InputStream9readValueERSt6vectorIhSaIhEEPKNS0_20ByteBufferDeploymentE(void *self, void *v, const void *d)
{
	REAL("_ZN9CommonAPI6SomeIP11InputStream9readValueERSt6vectorIhSaIhEEPKNS0_20ByteBufferDeploymentE", void *(*)(void *, void *, const void *));
	cur_self = self; void *r = real(self, v, d); LOG("bytebuffer"); return r;
}
void *_ZN9CommonAPI6SomeIP11InputStream8_readRawEm(void *self, unsigned long n)
{
	REAL("_ZN9CommonAPI6SomeIP11InputStream8_readRawEm", void *(*)(void *, unsigned long));
	cur_self = self; void *r = real(self, n); LOG("raw %lu%s", n, r ? "" : " (FAIL: past end)"); return r;
}
