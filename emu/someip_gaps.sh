#!/bin/bash
# Services requested on the bus but never offered (= what the car simulator must provide)
L=/srv/mgu22/vsomeipd.log
grep -aoE 'REQUEST\([0-9a-f]+\): \[[0-9a-f]{4}\.[0-9a-f]{4}' $L | sed -E 's/REQUEST\(([0-9a-f]+)\): \[/\1 /' | sort -u > /tmp/req
grep -aoE '(OFFER|offer)[^[]*\[[0-9a-f]{4}\.[0-9a-f]{4}' $L | grep -oE '[0-9a-f]{4}\.[0-9a-f]{4}' | sort -u > /tmp/off
echo "clients: $(cut -d' ' -f1 /tmp/req | sort -u | tr '\n' ' ')"
echo "requested: $(cut -d' ' -f2 /tmp/req | sort -u | wc -l)  offered: $(wc -l < /tmp/off)"
cut -d' ' -f2 /tmp/req | sort -u > /tmp/reqs
comm -23 /tmp/reqs /tmp/off > /tmp/gaps
echo "missing: $(wc -l < /tmp/gaps)"
tr '\n' ' ' < /tmp/gaps; echo
