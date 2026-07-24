# One image for all three VPN-lab roles (client, server, eavesdropper).
FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y --no-install-recommends \
        wireguard-tools iproute2 iputils-ping tcpdump curl python3 procps ca-certificates \
        openssh-server openssh-client \
    && rm -rf /var/lib/apt/lists/*
COPY *.sh /
COPY *.conf /etc/wireguard/
COPY login-server.py /login-server.py
RUN chmod +x /*.sh

# Real SSH between the lab machines: the student logs into the client and
# `ssh server` / `ssh eavesdropper` to do the real work. Host keys + a shared
# root keypair are baked in (all roles build from this one image, so any host
# can ssh any host as root, key-based) and the client config skips host-key
# prompts. Disposable teaching lab on an isolated network, so a baked key is fine.
RUN ssh-keygen -A \
    && mkdir -p /root/.ssh && chmod 700 /root/.ssh \
    && ssh-keygen -t ed25519 -N "" -f /root/.ssh/id_ed25519 \
    && cp /root/.ssh/id_ed25519.pub /root/.ssh/authorized_keys \
    && chmod 600 /root/.ssh/authorized_keys /root/.ssh/id_ed25519 \
    && printf 'Host *\n    StrictHostKeyChecking no\n    UserKnownHostsFile /dev/null\n    LogLevel ERROR\n    ConnectTimeout 5\n' > /root/.ssh/config \
    && chmod 600 /root/.ssh/config

# Security-workstation feel: welcome banner (with the network diagram), a host-
# aware `labhelp`, a `netmap` command, and a themed prompt on interactive login.
COPY motd /etc/motd-lab
COPY labhelp /usr/local/bin/labhelp
COPY netmap /usr/local/bin/netmap
# Install for BOTH shell types: /etc/profile.d for ssh login shells (ssh server),
# /etc/bash.bashrc for the docker-exec home shell (the client). The snippet is
# $--guarded so one-off `ssh host cmd` stays clean (no banner spam).
COPY lab-bashrc /etc/profile.d/00-lab-workstation.sh
RUN chmod 644 /etc/motd-lab /etc/profile.d/00-lab-workstation.sh \
    && chmod 755 /usr/local/bin/labhelp /usr/local/bin/netmap \
    && cat /etc/profile.d/00-lab-workstation.sh >> /etc/bash.bashrc

CMD ["sleep", "infinity"]
