/*
 * Minimal ivi-shell layout controller for running the MGU22 Hmi8 under weston.
 * In the car, BMW's window manager assigns ivi surfaces (CID, IC, HUD...) to layers.
 * Here every surface gets put on one full-screen layer at its native size, stacked by id,
 * and its id/size is logged so we can see which display each one is.
 *
 * Build: gcc -shared -fPIC -o mgu-ivi-controller.so mgu-ivi-controller.c $(pkg-config --cflags --libs libweston-13)
 * weston.ini: [core] shell=ivi-shell.so  modules=/srv/mgu22/mgu-ivi-controller.so
 * Env MGU_SHOW_ID=<ivi id> shows only that surface scaled to the window.
 */
#include <stdlib.h>
#include <stdbool.h>
#include <libweston/libweston.h>
#include <libweston/plugin-registry.h>
#include <weston/ivi-layout-export.h>

static const struct ivi_layout_interface *lyt;
static struct ivi_layout_layer *layer;
static struct weston_output *out;
static struct wl_listener l_create, l_config, l_remove;
static uint32_t show_id;
/* where the main HMI surface sits inside the output: window = main_x/y + hmi * main_k */
static int32_t main_w, main_h, main_x, main_y;
static double main_k = 1.0;

static void place(struct ivi_layout_surface *s)
{
	struct weston_surface *ws = lyt->surface_get_weston_surface(s);
	uint32_t id = lyt->get_id_of_surface(s);
	int32_t w = ws->width, h = ws->height;
	if (w <= 0 || h <= 0)
		return;
	bool vis = !show_id || id == show_id;
	lyt->surface_set_source_rectangle(s, 0, 0, w, h);
	/* scale to fit the window, keep aspect, centre */
	double k = (double)out->width / w;
	if (h * k > out->height)
		k = (double)out->height / h;
	if (!show_id && k > 1.0)
		k = 1.0;
	int32_t dw = (int32_t)(w * k), dh = (int32_t)(h * k);
	lyt->surface_set_destination_rectangle(s, (out->width - dw) / 2, (out->height - dh) / 2, dw, dh);
	lyt->surface_set_visibility(s, vis);
	if (vis && (int64_t)w * h >= (int64_t)main_w * main_h) {
		/* the largest visible surface is the CID; remember its mapping for injected taps */
		main_w = w; main_h = h; main_k = k;
		main_x = (out->width - dw) / 2; main_y = (out->height - dh) / 2;
	}
	lyt->commit_changes();
	weston_log("mgu-ivi: surface id=%u (0x%x) %dx%d visible=%d\n", id, id, w, h, vis);
}

static void on_create(struct wl_listener *l, void *data)
{
	struct ivi_layout_surface *s = data;
	weston_log("mgu-ivi: new surface id=%u\n", lyt->get_id_of_surface(s));
	lyt->layer_add_surface(layer, s);
	lyt->commit_changes();
}
static void on_config(struct wl_listener *l, void *data) { place(data); }
static void on_remove(struct wl_listener *l, void *data)
{
	weston_log("mgu-ivi: surface removed id=%u\n", lyt->get_id_of_surface(data));
}

/* ------------------------------------------------------------------------------------------
 * GENIVI ivi_controller (wayland-ivi-extension 1.9.0 wire protocol, as vendored by RAMSES 27).
 * RAMSES' SystemCompositorController_Wayland_IVI refuses to create a display unless this global
 * exists. We accept every request; visibility/opacity are applied to the real ivi-layout surface,
 * geometry stays under this module's scale-to-window placement.
 * ------------------------------------------------------------------------------------------ */
#include "ivi-controller-server-protocol.h"

static void destroy_res(struct wl_client *c, struct wl_resource *r, int32_t destroy_scene_object)
{
	(void)c; (void)destroy_scene_object;
	wl_resource_destroy(r);
}
static void destroy_res0(struct wl_client *c, struct wl_resource *r) { (void)c; wl_resource_destroy(r); }

static struct ivi_layout_surface *ctl_surface(struct wl_resource *r)
{
	uint32_t id = (uint32_t)(uintptr_t)wl_resource_get_user_data(r);
	return lyt->get_surface_from_id(id);
}
static void s_set_visibility(struct wl_client *c, struct wl_resource *r, uint32_t v)
{
	struct ivi_layout_surface *s = ctl_surface(r);
	weston_log("mgu-ivi: ctl surface %u visibility=%u\n", (uint32_t)(uintptr_t)wl_resource_get_user_data(r), v);
	if (s && !show_id)
		lyt->surface_set_visibility(s, v != 0);
}
static void s_set_opacity(struct wl_client *c, struct wl_resource *r, wl_fixed_t o)
{
	struct ivi_layout_surface *s = ctl_surface(r);
	if (s)
		lyt->surface_set_opacity(s, o);
}
static void s_rect(struct wl_client *c, struct wl_resource *r, int32_t x, int32_t y, int32_t w, int32_t h)
{
	weston_log("mgu-ivi: ctl surface %u rect %d,%d %dx%d (scaled to window instead)\n",
		   (uint32_t)(uintptr_t)wl_resource_get_user_data(r), x, y, w, h);
}
static void s_cfg(struct wl_client *c, struct wl_resource *r, int32_t w, int32_t h) {}
static void s_orient(struct wl_client *c, struct wl_resource *r, int32_t o) {}
static void s_shot(struct wl_client *c, struct wl_resource *r, const char *f) {}
static void s_stats(struct wl_client *c, struct wl_resource *r) {}
static const struct ivi_controller_surface_interface ctl_surface_impl = {
	s_set_visibility, s_set_opacity, s_rect, s_rect, s_cfg, s_orient, s_shot, s_stats, destroy_res,
};

static void l_vis(struct wl_client *c, struct wl_resource *r, uint32_t v) {}
static void l_op(struct wl_client *c, struct wl_resource *r, wl_fixed_t o) {}
static void l_clear(struct wl_client *c, struct wl_resource *r) {}
static void l_surf(struct wl_client *c, struct wl_resource *r, struct wl_resource *s) {}
static void l_order(struct wl_client *c, struct wl_resource *r, struct wl_array *a) {}
static const struct ivi_controller_layer_interface ctl_layer_impl = {
	l_vis, l_op, s_rect, s_rect, s_cfg, s_orient, s_shot, l_clear, l_surf, l_surf, l_order, destroy_res,
};

static void sc_layer(struct wl_client *c, struct wl_resource *r, struct wl_resource *l) {}
static const struct ivi_controller_screen_interface ctl_screen_impl = {
	destroy_res0, l_clear, sc_layer, s_shot, l_order,
};

static void c_commit(struct wl_client *c, struct wl_resource *r) { lyt->commit_changes(); }
static void c_layer_create(struct wl_client *c, struct wl_resource *r, uint32_t id_layer, int32_t w, int32_t h, uint32_t id)
{
	struct wl_resource *res = wl_resource_create(c, &ivi_controller_layer_interface, 1, id);
	if (!res) { wl_client_post_no_memory(c); return; }
	wl_resource_set_implementation(res, &ctl_layer_impl, (void *)(uintptr_t)id_layer, NULL);
}
static void c_surface_create(struct wl_client *c, struct wl_resource *r, uint32_t id_surface, uint32_t id)
{
	struct wl_resource *res = wl_resource_create(c, &ivi_controller_surface_interface, 1, id);
	if (!res) { wl_client_post_no_memory(c); return; }
	wl_resource_set_implementation(res, &ctl_surface_impl, (void *)(uintptr_t)id_surface, NULL);
	weston_log("mgu-ivi: ivi_controller.surface_create id=%u\n", id_surface);
}
static const struct ivi_controller_interface ctl_impl = { c_commit, c_layer_create, c_surface_create };

static void ctl_bind(struct wl_client *c, void *data, uint32_t version, uint32_t id)
{
	struct wl_resource *res = wl_resource_create(c, &ivi_controller_interface, 1, id);
	if (!res) { wl_client_post_no_memory(c); return; }
	wl_resource_set_implementation(res, &ctl_impl, NULL, NULL);
	weston_log("mgu-ivi: client bound ivi_controller\n");
}

/* Opaque black backdrop under the ivi layers so the window isn't see-through before the HMI draws. */
static struct weston_layer bg_layer;
static void make_background(struct weston_compositor *ec)
{
	struct weston_surface *s = weston_surface_create(ec);
	struct weston_buffer_reference *br = weston_buffer_create_solid_rgba(ec, 0.0f, 0.0f, 0.0f, 1.0f);
	if (!s || !br)
		return;
	weston_surface_attach_solid(s, br, out->width, out->height);
	pixman_region32_fini(&s->opaque);
	pixman_region32_init_rect(&s->opaque, 0, 0, out->width, out->height);
	struct weston_view *v = weston_view_create(s);
	weston_layer_init(&bg_layer, ec);
	weston_layer_set_position(&bg_layer, WESTON_LAYER_POSITION_BACKGROUND);
	struct weston_coord_global pos = { .c = { .x = out->pos.c.x, .y = out->pos.c.y } };
	weston_view_set_position(v, pos);
	weston_view_move_to_layer(v, &bg_layer.view_list);
	weston_surface_map(s);
	weston_view_schedule_repaint(v);
}

/* ------------------------------------------------------------------------------------------
 * Scripted input: commands written to /srv/mgu22/input.fifo become real seat pointer events,
 * exactly as if the mouse did it, so the HMI's own window input path (RAMSES -> touch) runs.
 * Coordinates are in HMI pixels (1920x640 CID space), not window pixels.
 *   tap X Y | down X Y | move X Y | up | swipe X1 Y1 X2 Y2 [ms]
 * ------------------------------------------------------------------------------------------ */
#include <stdio.h>
#include <string.h>
#include <fcntl.h>
#include <unistd.h>
#include <time.h>
#include <sys/stat.h>
#include <linux/input-event-codes.h>

/* exported by libweston-13 but only declared in its private backend.h */
void notify_motion_absolute(struct weston_seat *seat, const struct timespec *time, struct weston_coord_global pos);
void notify_button(struct weston_seat *seat, const struct timespec *time, int32_t button,
		   enum wl_pointer_button_state state);
void notify_pointer_frame(struct weston_seat *seat);

#define FIFO_PATH "/srv/mgu22/input.fifo"
#define STEP_MS 30
enum step_kind { ST_MOVE, ST_DOWN, ST_UP };
struct step { enum step_kind kind; double x, y; };
static struct step steps[512];
static int n_steps, cur_step;
static struct weston_compositor *comp;
static struct wl_event_source *step_timer;
static char fifo_buf[512];
static size_t fifo_len;

static struct weston_seat *pointer_seat(void)
{
	struct weston_seat *seat;
	wl_list_for_each(seat, &comp->seat_list, link)
		if (weston_seat_get_pointer(seat))
			return seat;
	return NULL;
}

static void push(enum step_kind k, double x, double y)
{
	if (n_steps < (int)(sizeof(steps) / sizeof(steps[0])))
		steps[n_steps++] = (struct step){ k, x, y };
}

static int run_step(void *data)
{
	struct weston_seat *seat = pointer_seat();
	if (!seat || cur_step >= n_steps) {
		if (!seat)
			weston_log("mgu-ivi: no seat with a pointer - input dropped\n");
		n_steps = cur_step = 0;
		return 0;
	}
	struct step *s = &steps[cur_step++];
	struct timespec now;
	clock_gettime(CLOCK_MONOTONIC, &now);
	if (s->kind == ST_UP) {
		notify_button(seat, &now, BTN_LEFT, WL_POINTER_BUTTON_STATE_RELEASED);
	} else {
		struct weston_coord_global p = { .c = {
			.x = out->pos.c.x + main_x + s->x * main_k,
			.y = out->pos.c.y + main_y + s->y * main_k } };
		notify_motion_absolute(seat, &now, p);
		if (s->kind == ST_DOWN) {
			struct weston_pointer *ptr = weston_seat_get_pointer(seat);
			weston_log("mgu-ivi: down at window %.0f,%.0f focus=%p\n", p.c.x, p.c.y,
				   ptr ? (void *)ptr->focus : NULL);
			notify_pointer_frame(seat);
			notify_button(seat, &now, BTN_LEFT, WL_POINTER_BUTTON_STATE_PRESSED);
		}
	}
	notify_pointer_frame(seat);
	wl_event_source_timer_update(step_timer, STEP_MS);
	return 0;
}

static void parse_cmd(char *line)
{
	double a, b, c, d, ms = 300;
	bool idle = cur_step >= n_steps;
	if (idle)
		n_steps = cur_step = 0;
	/* The HMI takes its position from wl_pointer.motion only (enter coords are ignored), and
	 * weston drops motion to the same spot, so every approach comes in from 2px to the left. */
	if (sscanf(line, "tap %lf %lf", &a, &b) == 2) {
		push(ST_MOVE, a - 2, b); push(ST_MOVE, a, b); push(ST_DOWN, a, b);
		push(ST_MOVE, a, b); push(ST_MOVE, a, b); push(ST_UP, a, b);
	} else if (sscanf(line, "swipe %lf %lf %lf %lf %lf", &a, &b, &c, &d, &ms) >= 4) {
		int n = (int)(ms / STEP_MS);
		if (n < 2) n = 2;
		push(ST_MOVE, a - 2, b); push(ST_MOVE, a, b); push(ST_DOWN, a, b);
		for (int i = 1; i <= n; i++)
			push(ST_MOVE, a + (c - a) * i / n, b + (d - b) * i / n);
		push(ST_UP, c, d);
	} else if (sscanf(line, "down %lf %lf", &a, &b) == 2) {
		push(ST_MOVE, a - 2, b); push(ST_MOVE, a, b); push(ST_DOWN, a, b);
	} else if (sscanf(line, "move %lf %lf", &a, &b) == 2) {
		push(ST_MOVE, a, b);
	} else if (strncmp(line, "up", 2) == 0) {
		push(ST_UP, 0, 0);
	} else {
		weston_log("mgu-ivi: input.fifo: unknown command '%s'\n", line);
		return;
	}
	weston_log("mgu-ivi: input '%s'\n", line);
	if (idle)
		wl_event_source_timer_update(step_timer, 1);
}

static int on_fifo(int fd, uint32_t mask, void *data)
{
	ssize_t r = read(fd, fifo_buf + fifo_len, sizeof(fifo_buf) - 1 - fifo_len);
	if (r <= 0)
		return 0;
	fifo_len += r;
	fifo_buf[fifo_len] = 0;
	char *nl;
	while ((nl = strchr(fifo_buf, '\n'))) {
		*nl = 0;
		if (nl > fifo_buf && nl[-1] == '\r')
			nl[-1] = 0;
		parse_cmd(fifo_buf);
		fifo_len -= nl + 1 - fifo_buf;
		memmove(fifo_buf, nl + 1, fifo_len + 1);
	}
	if (fifo_len == sizeof(fifo_buf) - 1)
		fifo_len = 0; /* garbage line, drop it */
	return 0;
}

/* ------------------------------------------------------------------------------------------
 * Mouse -> CID touchscreen. The car's HMI reads its touch panel (udev alias
 * /dev/input/cid-touchscreen, device name "cid-tsc") through mtdev on a dedicated reader thread.
 * Its Wayland pointer fallback goes through the UI main loop, which under qemu dispatches input
 * so late that every tap turns into a long-press. So we create that panel with uinput and turn
 * left-button down/drag/up into finger down/move/up; the button itself never reaches the client.
 * ------------------------------------------------------------------------------------------ */
#include <errno.h>
#include <dirent.h>
#include <sys/ioctl.h>
#include <linux/uinput.h>

/* panel size = the profile's CID resolution (run_hmi.sh exports MGU_TSC_W/H) */
static int tsc_w = 1920, tsc_h = 640;
#define TSC_W tsc_w
#define TSC_H tsc_h
#define TSC_LINK "/dev/input/cid-touchscreen"
static int tsc_fd = -1;
static int tsc_tracking;
static struct weston_pointer_grab touch_grab;

static void tsc_ev(uint16_t type, uint16_t code, int32_t value)
{
	struct input_event e = { .type = type, .code = code, .value = value };
	if (write(tsc_fd, &e, sizeof(e)) != (ssize_t)sizeof(e))
		weston_log("mgu-ivi: uinput write failed: %s\n", strerror(errno));
}

static void abs_axis(uint16_t code, int32_t max)
{
	struct uinput_abs_setup a = { .code = code, .absinfo = { .minimum = 0, .maximum = max } };
	ioctl(tsc_fd, UI_SET_ABSBIT, code);
	ioctl(tsc_fd, UI_ABS_SETUP, &a);
}

static int tsc_create(void)
{
	const char *ew = getenv("MGU_TSC_W"), *eh = getenv("MGU_TSC_H");
	if (ew && atoi(ew) > 0) tsc_w = atoi(ew);
	if (eh && atoi(eh) > 0) tsc_h = atoi(eh);
	tsc_fd = open("/dev/uinput", O_WRONLY | O_NONBLOCK | O_CLOEXEC);
	if (tsc_fd < 0) {
		weston_log("mgu-ivi: /dev/uinput: %s (modprobe uinput?)\n", strerror(errno));
		return -1;
	}
	ioctl(tsc_fd, UI_SET_EVBIT, EV_KEY);
	ioctl(tsc_fd, UI_SET_KEYBIT, BTN_TOUCH);
	ioctl(tsc_fd, UI_SET_EVBIT, EV_ABS);
	ioctl(tsc_fd, UI_SET_PROPBIT, INPUT_PROP_DIRECT);
	abs_axis(ABS_X, TSC_W - 1);
	abs_axis(ABS_Y, TSC_H - 1);
	abs_axis(ABS_MT_SLOT, 9);
	abs_axis(ABS_MT_TRACKING_ID, 65535);
	abs_axis(ABS_MT_POSITION_X, TSC_W - 1);
	abs_axis(ABS_MT_POSITION_Y, TSC_H - 1);
	abs_axis(ABS_MT_PRESSURE, 255);
	struct uinput_setup us = { .id = { .bustype = BUS_I2C, .vendor = 0x0bb, .product = 0x0cd } };
	snprintf(us.name, sizeof(us.name), "cid-tsc");
	if (ioctl(tsc_fd, UI_DEV_SETUP, &us) < 0 || ioctl(tsc_fd, UI_DEV_CREATE) < 0) {
		weston_log("mgu-ivi: uinput create failed: %s\n", strerror(errno));
		close(tsc_fd);
		tsc_fd = -1;
		return -1;
	}
	/* no udev in WSL: find our eventN and make the alias the HMI opens */
	char sys[64] = "", path[160], node[64] = "";
	ioctl(tsc_fd, UI_GET_SYSNAME(sizeof(sys)), sys);
	snprintf(path, sizeof(path), "/sys/devices/virtual/input/%s", sys);
	for (int tries = 0; tries < 50 && !node[0]; tries++) {
		DIR *d = opendir(path);
		struct dirent *de;
		while (d && (de = readdir(d)))
			if (!strncmp(de->d_name, "event", 5))
				snprintf(node, sizeof(node), "%s", de->d_name);
		if (d)
			closedir(d);
		if (!node[0])
			usleep(20000);
	}
	mkdir("/dev/input", 0755);
	unlink(TSC_LINK);
	if (!node[0] || symlink(node, TSC_LINK) < 0) {
		weston_log("mgu-ivi: could not link %s (node '%s')\n", TSC_LINK, node);
		return -1;
	}
	weston_log("mgu-ivi: touchscreen cid-tsc %dx%d at /dev/input/%s -> %s\n", TSC_W, TSC_H, node, TSC_LINK);
	return 0;
}

static void to_hmi(struct weston_coord_global p, int32_t *x, int32_t *y)
{
	double hx = (p.c.x - out->pos.c.x - main_x) / main_k;
	double hy = (p.c.y - out->pos.c.y - main_y) / main_k;
	*x = hx < 0 ? 0 : hx > TSC_W - 1 ? TSC_W - 1 : (int32_t)hx;
	*y = hy < 0 ? 0 : hy > TSC_H - 1 ? TSC_H - 1 : (int32_t)hy;
}

static void tsc_finger(bool down, struct weston_coord_global p)
{
	int32_t x, y;
	to_hmi(p, &x, &y);
	tsc_ev(EV_ABS, ABS_MT_SLOT, 0);
	if (down) {
		tsc_ev(EV_ABS, ABS_MT_TRACKING_ID, tsc_tracking++ & 0xffff);
		tsc_ev(EV_ABS, ABS_MT_PRESSURE, 200);
		tsc_ev(EV_KEY, BTN_TOUCH, 1);
	}
	if (down) {
		/* evdev drops values equal to the last one; a new touch must always carry its position */
		tsc_ev(EV_ABS, ABS_MT_POSITION_X, x ^ 1);
		tsc_ev(EV_ABS, ABS_MT_POSITION_Y, y ^ 1);
		tsc_ev(EV_ABS, ABS_X, x ^ 1);
		tsc_ev(EV_ABS, ABS_Y, y ^ 1);
	}
	tsc_ev(EV_ABS, ABS_MT_POSITION_X, x);
	tsc_ev(EV_ABS, ABS_MT_POSITION_Y, y);
	tsc_ev(EV_ABS, ABS_X, x);
	tsc_ev(EV_ABS, ABS_Y, y);
	tsc_ev(EV_SYN, SYN_REPORT, 0);
}

static void tsc_lift(void)
{
	tsc_ev(EV_ABS, ABS_MT_SLOT, 0);
	tsc_ev(EV_ABS, ABS_MT_TRACKING_ID, -1);
	tsc_ev(EV_KEY, BTN_TOUCH, 0);
	tsc_ev(EV_SYN, SYN_REPORT, 0);
}

static void tg_focus(struct weston_pointer_grab *g) {}
static void tg_motion(struct weston_pointer_grab *g, const struct timespec *time, struct weston_pointer_motion_event *ev)
{
	weston_pointer_move(g->pointer, ev); /* finger is down: drag, don't hover */
	tsc_finger(false, g->pointer->pos);
}
static void tg_button(struct weston_pointer_grab *g, const struct timespec *time, uint32_t button, uint32_t state)
{
	if (state == WL_POINTER_BUTTON_STATE_RELEASED && g->pointer->button_count == 0) {
		tsc_lift();
		weston_pointer_end_grab(g->pointer);
	}
}
static void tg_axis(struct weston_pointer_grab *g, const struct timespec *time, struct weston_pointer_axis_event *ev) {}
static void tg_axis_source(struct weston_pointer_grab *g, uint32_t source) {}
static void tg_frame(struct weston_pointer_grab *g) {}
static void tg_cancel(struct weston_pointer_grab *g)
{
	tsc_lift();
	weston_pointer_end_grab(g->pointer);
}
static const struct weston_pointer_grab_interface touch_grab_impl = {
	tg_focus, tg_motion, tg_button, tg_axis, tg_axis_source, tg_frame, tg_cancel,
};

/* button bindings run before the grab sees the press, so the press never reaches the client */
static void on_left_press(struct weston_pointer *pointer, const struct timespec *time, uint32_t button, void *data)
{
	if (pointer->button_count != 1 || !main_w)
		return;
	touch_grab.interface = &touch_grab_impl;
	weston_pointer_start_grab(pointer, &touch_grab);
	tsc_finger(true, pointer->pos);
}

static void setup_input_fifo(struct weston_compositor *ec)
{
	if (tsc_create() == 0)
		weston_compositor_add_button_binding(ec, BTN_LEFT, 0, on_left_press, NULL);
	else
		weston_log("mgu-ivi: no uinput touchscreen - mouse goes to the HMI as wl_pointer\n");

	comp = ec;
	unlink(FIFO_PATH);
	if (mkfifo(FIFO_PATH, 0666) < 0) {
		weston_log("mgu-ivi: mkfifo %s failed\n", FIFO_PATH);
		return;
	}
	/* O_RDWR keeps a writer open ourselves, so the fifo never reports EOF between commands */
	int fd = open(FIFO_PATH, O_RDWR | O_NONBLOCK | O_CLOEXEC);
	if (fd < 0)
		return;
	struct wl_event_loop *loop = wl_display_get_event_loop(ec->wl_display);
	wl_event_loop_add_fd(loop, fd, WL_EVENT_READABLE, on_fifo, NULL);
	step_timer = wl_event_loop_add_timer(loop, run_step, NULL);
}

WL_EXPORT int wet_module_init(struct weston_compositor *ec, int *argc, char *argv[])
{
	lyt = weston_plugin_api_get(ec, IVI_LAYOUT_API_NAME, sizeof(*lyt));
	if (!lyt) {
		weston_log("mgu-ivi: ivi-shell layout api missing (load ivi-shell.so)\n");
		return -1;
	}
	if (wl_list_empty(&ec->output_list)) {
		weston_log("mgu-ivi: no output\n");
		return -1;
	}
	const char *sid = getenv("MGU_SHOW_ID");
	show_id = sid ? (uint32_t)strtoul(sid, NULL, 0) : 0;
	out = wl_container_of(ec->output_list.next, out, link);
	make_background(ec);
	setup_input_fifo(ec);
	layer =lyt->layer_create_with_dimension(1000, out->width, out->height);
	lyt->screen_add_layer(out, layer);
	lyt->layer_set_visibility(layer, true);
	l_create.notify = on_create;
	l_config.notify = on_config;
	l_remove.notify = on_remove;
	lyt->add_listener_create_surface(&l_create);
	lyt->add_listener_configure_surface(&l_config);
	lyt->add_listener_remove_surface(&l_remove);
	lyt->commit_changes();
	if (!wl_global_create(ec->wl_display, &ivi_controller_interface, 1, NULL, ctl_bind))
		weston_log("mgu-ivi: failed to create ivi_controller global\n");
	weston_log("mgu-ivi: controller ready on %dx%d (ivi_controller v1 exported)\n", out->width, out->height);
	return 0;
}
