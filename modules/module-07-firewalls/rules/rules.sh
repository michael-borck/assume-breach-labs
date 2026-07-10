#!/bin/sh
# ---------------------------------------------------------------------------
# Reference firewall ruleset — Module 07, Exercises 4-6.
#
# This reproduces the original iNetworkSimulator lab with REAL iptables:
#
#   Rule 0 (Drop)   pc2 -> pc1 ICMP   silently discarded   -> DROP
#   Rule 1 (Deny)   pc3 -> pc1 ICMP   rejected with error  -> REJECT (host-unreachable)
#   Rule 2 (Permit) anything else     allowed              -> ACCEPT  (catch-all)
#
# The difference students must observe:
#   DROP   -> ping just times out (100% loss, no reply at all)
#   REJECT -> ping reports "Destination Host Unreachable" (an active refusal)
#
# Run this on the firewall:   /rules/rules.sh
# Then re-run the pings from pc2, pc3, pc4 and compare.
# ---------------------------------------------------------------------------
set -e

PC1=10.1.1.2
PC2=10.1.2.3
PC3=10.1.2.4

iptables -F FORWARD

# Rule 0: DROP  (the worksheet's "Drop")
iptables -A FORWARD -p icmp -s "$PC2" -d "$PC1" -j DROP

# Rule 1: DENY  (the worksheet's "Deny" = an active ICMP refusal)
iptables -A FORWARD -p icmp -s "$PC3" -d "$PC1" -j REJECT --reject-with icmp-host-unreachable

# Rule 2: PERMIT everything else (catch-all)
iptables -A FORWARD -j ACCEPT

echo "Ruleset loaded:"
iptables -L FORWARD -n -v --line-numbers
