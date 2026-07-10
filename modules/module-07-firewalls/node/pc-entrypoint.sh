#!/bin/sh
# Workstation entrypoint. Adds a route to the far subnet via the firewall so all
# cross-network traffic is forced through it (that is the whole point of the lab).
set -e

if [ -n "$ROUTE_NET" ] && [ -n "$ROUTE_GW" ]; then
    ip route replace "$ROUTE_NET" via "$ROUTE_GW"
fi

# Point this workstation at the lab DNS server, if one was provided.
if [ -n "$DNS_SERVER" ]; then
    echo "nameserver $DNS_SERVER" > /etc/resolv.conf
fi

echo "[$(hostname)] ready"
ip -4 -brief addr show | grep -v '^lo'
echo "[$(hostname)] routes:"
ip route

exec sleep infinity
