#!/bin/sh
# Shared Module 07 node setup, called by both the firewall and workstation
# entrypoints. Gives every lab machine (a) friendly name resolution so students
# can `ssh pc2` / `ping pc1` instead of memorising IPs, and (b) a running SSH
# server so they can hop between the real machines. The SSH keys are baked into
# the image (see node/Dockerfile), so `ssh pc2` from the firewall just works.

# Friendly names for the lab hosts.
cat >> /etc/hosts <<'EOF'
10.1.1.2   pc1
10.1.2.3   pc2
10.1.2.4   pc3
10.1.2.5   pc4
10.1.1.253 dns
10.1.1.254 firewall
EOF

# Start the SSH server (key-based root login; keys are baked into the image).
mkdir -p /run/sshd
/usr/sbin/sshd 2>/dev/null || true
