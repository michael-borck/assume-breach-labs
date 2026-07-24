#!/bin/sh
# Shared Module 11 node setup, called by the client/server/eavesdropper
# entrypoints. Gives every machine (a) friendly name resolution so the student
# can `ssh server` / `ssh eavesdropper` / `curl http://server:8080`, and (b) a
# running SSH server so they can hop between the real machines. The SSH keys are
# baked into the image (see node/Dockerfile), so `ssh server` from the client
# just works.

cat >> /etc/hosts <<'EOF'
10.11.0.10  client
10.11.1.20  server
10.11.0.254 eavesdropper
EOF

mkdir -p /run/sshd
/usr/sbin/sshd 2>/dev/null || true
