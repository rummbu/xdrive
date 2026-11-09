#!/bin/bash
# iface_members.sh <lib-substring> <ProxyClass> : list attributes/methods/broadcasts of a CommonAPI SomeIP proxy
R=/srv/mgu22/root
L=$(ls $R/usr/lib/*$1*proxy.someip.so* $R/opt/ivi/rootfs/usr/lib/*$1*proxy.someip.so* 2>/dev/null | grep -v '\.so\.[0-9.-]*\.1$' | head -1)
[ -z "$L" ] && L=$(ls $R/usr/lib/*$1*proxy.someip.so* $R/opt/ivi/rootfs/usr/lib/*$1*proxy.someip.so* 2>/dev/null | head -1)
echo "lib: $L"
aarch64-linux-gnu-nm -DC --defined-only "$L" | grep -E "$2SomeIPProxy::(get[A-Za-z0-9]+(Attribute|Event)\(\)|[a-z][A-Za-z0-9]+\()" \
  | sed -E 's/^[0-9a-f]+ [A-Za-z] //' | sed -E 's/v[0-9]+::de::bmw::[a-z:]+:://g' | sort -u | cut -c1-260 | head -${3:-80}
