#!/bin/bash
R=/srv/mgu22/root
L=$(ls $R/usr/lib/libramses-shared-lib-wayland-ivi-egl-es-3-0.so.27.0* $R/opt/ivi/rootfs/usr/lib/libramses-shared-lib-wayland-ivi-egl-es-3-0.so.27.0* 2>/dev/null | head -1)
echo "lib: $L"
echo "== ivi interface names + method/event names + signatures embedded in ramses"
strings -n 2 $L | grep -nE '^ivi_|^(screen|layer|surface|controller|commit_changes|set_|layer_|surface_|screen_|get_|destroy|create|add_|remove_|visibility|opacity|source_rectangle|destination_rectangle|configuration|error|created|destroyed|id_assignment|stats|content|requested|clear|screenshot|done|identifier|render_order|layers|layer_created|surface_created|orientation|input_focus|dimension|position|stats|screen_)' | head -120
