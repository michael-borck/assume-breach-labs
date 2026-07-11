#!/bin/sh
ip route replace 10.11.0.0/24 via 10.11.1.254 2>/dev/null || true
cp /etc/wireguard/server-wg0.conf /etc/wireguard/wg0.conf
python3 /login-server.py >/var/log/login.log 2>&1 &
echo "[server] cleartext login service on :8080."
exec sleep infinity
