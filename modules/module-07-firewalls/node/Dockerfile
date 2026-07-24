# Self-contained dual-purpose image for Module 07: used for the firewall (router),
# the workstations (pc1-pc4), and the DNS server. Rules and DNS config are BAKED IN
# (not bind-mounted) so the image works identically whether pulled from GHCR or
# built locally, and so it doesn't depend on host file-sharing (which is fragile on
# external/exFAT drives). Kept tiny so it builds fast with the legacy builder.
#
# Build context is the module directory (see docker-compose.yml), so this Dockerfile
# can COPY from node/, rules/, and dnsmasq/.
FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
        iproute2 \
        iptables \
        iputils-ping \
        tcpdump \
        dnsutils \
        dnsmasq \
        procps \
        openssh-server \
        openssh-client \
    && rm -rf /var/lib/apt/lists/*

COPY node/firewall-entrypoint.sh /firewall-entrypoint.sh
COPY node/pc-entrypoint.sh /pc-entrypoint.sh
COPY node/lab-node-setup.sh /lab-node-setup.sh
COPY rules/rules.sh /rules/rules.sh
COPY dnsmasq/dnsmasq.conf /etc/dnsmasq/dnsmasq.conf
RUN chmod +x /firewall-entrypoint.sh /pc-entrypoint.sh /lab-node-setup.sh /rules/rules.sh

# Real SSH between the lab machines: students log into the firewall and `ssh pc2`
# to test. Host keys + a shared root keypair are baked in — every host builds
# from this one image, so any host can ssh any host as root, key-based — and the
# client config skips host-key prompts. This is a disposable teaching lab on an
# isolated network, not production, so a baked lab key is acceptable.
RUN ssh-keygen -A \
    && mkdir -p /root/.ssh && chmod 700 /root/.ssh \
    && ssh-keygen -t ed25519 -N "" -f /root/.ssh/id_ed25519 \
    && cp /root/.ssh/id_ed25519.pub /root/.ssh/authorized_keys \
    && chmod 600 /root/.ssh/authorized_keys /root/.ssh/id_ed25519 \
    && printf 'Host *\n    StrictHostKeyChecking no\n    UserKnownHostsFile /dev/null\n    LogLevel ERROR\n    ConnectTimeout 5\n' > /root/.ssh/config \
    && chmod 600 /root/.ssh/config

# Security-workstation feel: welcome banner (with the network diagram), a host-
# aware `labhelp`, a `netmap` command, and a themed prompt on every interactive
# login. All these hosts run as root, so plain modes are fine.
COPY node/motd /etc/motd-lab
COPY node/labhelp /usr/local/bin/labhelp
COPY node/netmap /usr/local/bin/netmap
# Install for BOTH shell types: /etc/profile.d for ssh login shells (ssh pc2),
# /etc/bash.bashrc for the docker-exec home shell (the firewall). The snippet is
# $--guarded so one-off `ssh host cmd` stays clean (no banner spam).
COPY node/lab-bashrc /etc/profile.d/00-lab-workstation.sh
RUN chmod 644 /etc/motd-lab /etc/profile.d/00-lab-workstation.sh \
    && chmod 755 /usr/local/bin/labhelp /usr/local/bin/netmap \
    && cat /etc/profile.d/00-lab-workstation.sh >> /etc/bash.bashrc

CMD ["sleep", "infinity"]
