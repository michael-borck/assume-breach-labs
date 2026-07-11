#!/bin/sh
# Send credentials to the server. If the VPN tunnel is up, go through it (the
# tunnel IP); otherwise go direct over the untrusted network.
if ip link show wg0 >/dev/null 2>&1; then TARGET=10.99.0.1; else TARGET=10.11.1.20; fi
curl -s -m 5 "http://$TARGET:8080/login" -d "user=admin&password=Sup3rSecret!" >/dev/null 2>&1
echo "[client] sent login to $TARGET:8080"
