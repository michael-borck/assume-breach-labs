# Shared toolbox image for the Assume Breach labs.
#
# Published to GHCR as ghcr.io/michael-borck/assume-breach-base by
# .github/workflows/build-base.yml, so most modules start with a plain pull.
# Build locally with `make build-base` (tags the local build with the same name).
#
# Kept close to the ethical-hacking-docker-labs base so the two series share tools,
# but trimmed toward a defensive/first-course toolset.
FROM kalilinux/kali-rolling

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        nmap \
        john \
        hashcat \
        hydra \
        fcrackzip \
        crunch \
        openssl \
        gnupg \
        tshark \
        tcpdump \
        iproute2 \
        iptables \
        iputils-ping \
        dnsutils \
        netcat-traditional \
        openssh-client \
        curl \
        wget \
        ca-certificates \
        python3 \
        python3-pip \
        wordlists \
        && rm -rf /var/lib/apt/lists/* \
        && gunzip -f /usr/share/wordlists/rockyou.txt.gz 2>/dev/null || true

# Unprivileged lab user
RUN useradd -m -s /bin/bash analyst && \
    echo 'analyst:analyst' | chpasswd

USER analyst
WORKDIR /home/analyst
CMD ["/bin/bash"]
