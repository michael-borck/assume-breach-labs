# One image for all three VPN-lab roles (client, server, eavesdropper).
FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y --no-install-recommends \
        wireguard-tools iproute2 iputils-ping tcpdump curl python3 procps ca-certificates \
    && rm -rf /var/lib/apt/lists/*
COPY *.sh /
COPY *.conf /etc/wireguard/
COPY login-server.py /login-server.py
RUN chmod +x /*.sh
CMD ["sleep", "infinity"]
