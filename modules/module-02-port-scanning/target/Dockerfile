# One reusable "target machine" image for Module 02. Each instance starts a
# different set of services (via env), so a scan of the network turns up hosts
# with distinct service profiles — just like a real network.
FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
        openssh-server \
        vsftpd \
        python3 \
        ca-certificates \
    && rm -rf /var/lib/apt/lists/*

COPY entrypoint.sh /entrypoint.sh
COPY banner.py /banner.py
RUN chmod +x /entrypoint.sh

CMD ["/entrypoint.sh"]
