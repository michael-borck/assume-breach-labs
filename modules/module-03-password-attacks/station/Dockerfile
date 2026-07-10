# Cracking workstation for Module 03. Built on the shared toolbox image, which
# carries the JUMBO John the Ripper (needed for raw-md5 / raw-sha256 / NT formats),
# hashcat, fcrackzip, and the rockyou wordlist. Lab data (~10 KB) is baked in — no
# bind mounts, so it works on external/exFAT drives and pulls cleanly from GHCR.
FROM ghcr.io/michael-borck/assume-breach-base:latest

# Base image runs as the unprivileged 'analyst' user; drop to root to place files.
USER root
COPY --chown=analyst:analyst data /home/analyst/lab
RUN chmod +x /home/analyst/lab/scripts/identify-hash.py \
    && ln -s /home/analyst/lab/scripts/identify-hash.py /usr/local/bin/identify-hash \
    && chown -R analyst:analyst /home/analyst

USER analyst
WORKDIR /home/analyst/lab
CMD ["sleep", "infinity"]
