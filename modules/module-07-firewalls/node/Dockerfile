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
    && rm -rf /var/lib/apt/lists/*

COPY node/firewall-entrypoint.sh /firewall-entrypoint.sh
COPY node/pc-entrypoint.sh /pc-entrypoint.sh
COPY rules/rules.sh /rules/rules.sh
COPY dnsmasq/dnsmasq.conf /etc/dnsmasq/dnsmasq.conf
RUN chmod +x /firewall-entrypoint.sh /pc-entrypoint.sh /rules/rules.sh

CMD ["sleep", "infinity"]
