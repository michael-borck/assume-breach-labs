#!/bin/sh
# Firewall/router entrypoint. Enables IP forwarding and starts with NO filter
# rules (default ACCEPT), so students see an open network first and then apply
# the ruleset themselves.
set -e

# Set ip_forward here, not via compose `sysctls:`: rootless Podman rejects
# privileged sysctls during container creation, but this runs inside the
# container's own network namespace.
sysctl -w net.ipv4.ip_forward=1 >/dev/null 2>&1 || true

# Name resolution for the lab hosts + start the SSH server (shared with the pcs).
/lab-node-setup.sh

echo "=============================================="
echo " Firewall up. IP forwarding: $(cat /proc/sys/net/ipv4/ip_forward)"
echo " Inside : 10.1.1.254/24   Outside: 10.1.2.254/24"
echo " No filter rules loaded yet (default ACCEPT)."
echo ""
echo " Load the teaching ruleset with:   /rules/rules.sh"
echo " Inspect rules with:               iptables -L FORWARD -n -v --line-numbers"
echo "=============================================="

exec sleep infinity
