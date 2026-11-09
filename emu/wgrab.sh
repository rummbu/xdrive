#!/bin/bash
H=/usr/include/libweston-13/libweston/libweston.h
grep -n -A10 'struct weston_pointer_grab_interface {' $H
grep -nE 'weston_pointer_(send_(motion|button|axis|axis_source|frame)|start_grab|end_grab|move|clear_focus)\(|weston_compositor_add_button_binding|struct weston_pointer_grab \{|grab_button|grab_pos|button_count' $H | head -30
grep -n -B2 -A8 'struct weston_pointer_motion_event {' $H
