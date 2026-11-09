#!/bin/bash
L=$(ls /srv/mgu22/root/usr/lib/libCommonAPI-SomeIP.so* | grep -v '\.so$' | head -1); echo "$L"
aarch64-linux-gnu-nm -D --defined-only "$L" | awk '{print $3}' | grep -E 'InputStream|7Message' > /tmp/capi_syms.txt
while read s; do printf '%s\t%s\n' "$s" "$(echo "$s" | c++filt | cut -c1-160)"; done < /tmp/capi_syms.txt | grep -E 'readValue|_read|InputStream\(|getServiceId|getMethodId|getPayload'
