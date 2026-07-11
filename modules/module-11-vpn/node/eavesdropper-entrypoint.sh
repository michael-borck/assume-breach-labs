#!/bin/sh
# The untrusted hop between the two networks: forwards traffic and can sniff it.
sysctl -w net.ipv4.ip_forward=1 >/dev/null 2>&1 || true
echo "[eavesdropper] on-path between client and server. Forwarding + sniffing."
exec sleep infinity
