#!/bin/bash
# caf_q.sh REGEX [area]  - query decoded coding flags
python3 -I "$(cat /srv/mgu22/repo_root)/emu/caf_flags.py" /srv/mgu22/cafd_l.json "$1" $2
