#!/bin/sh
# Route to the datacentre network THROUGH the untrusted hop (the eavesdropper).
ip route replace 10.11.1.0/24 via 10.11.0.254 2>/dev/null || true
cp /etc/wireguard/client-wg0.conf /etc/wireguard/wg0.conf
echo "[client] ready — traffic to the server crosses the untrusted network (via 10.11.0.254)."
exec sleep infinity
