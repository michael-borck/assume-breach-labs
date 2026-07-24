#!/bin/sh
# The untrusted hop between the two networks: forwards traffic and can sniff it.
sysctl -w net.ipv4.ip_forward=1 >/dev/null 2>&1 || true

# Name resolution for the lab hosts + start the SSH server (so the student can
# ssh here from the client to read the captured wire).
/lab-node-setup.sh

# Persistent capture of the wire between client and server, so the student can
# read what crossed it: `ssh eavesdropper 'grep password /var/log/wire.log'`.
# Captures cleartext logins (tcp 8080) and WireGuard tunnel traffic (udp 51820).
mkdir -p /var/log
: > /var/log/wire.log
tcpdump -A -nn -l -i any 'tcp port 8080 or udp port 51820' >> /var/log/wire.log 2>/dev/null &

echo "[eavesdropper] on-path between client and server. Forwarding + sniffing to /var/log/wire.log."
exec sleep infinity
