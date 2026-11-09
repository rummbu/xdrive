#!/bin/bash
# prints 1 if the current weston session shows the HMI surface as visible
tac /srv/mgu22/weston.log 2>/dev/null | awk '/controller ready/{exit} /visible=1/{v=1} END{print v+0}'
