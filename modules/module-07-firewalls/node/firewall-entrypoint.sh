#!/bin/sh
# Firewall/router entrypoint. Enables IP forwarding and starts with NO filter
# rules (default ACCEPT), so students see an open network first and then apply
# the ruleset themselves.
set -e

# ip_forward is normally set via the compose `sysctls:` key; this is a fallback.
sysctl -w net.ipv4.ip_forward=1 >/dev/null 2>&1 || true

echo "=============================================="
echo " Firewall up. IP forwarding: $(cat /proc/sys/net/ipv4/ip_forward)"
echo " Inside : 10.1.1.254/24   Outside: 10.1.2.254/24"
echo " No filter rules loaded yet (default ACCEPT)."
echo ""
echo " Load the teaching ruleset with:   /rules/rules.sh"
echo " Inspect rules with:               iptables -L FORWARD -n -v --line-numbers"
echo "=============================================="

exec sleep infinity
