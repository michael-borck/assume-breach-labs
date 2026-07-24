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

# Security-workstation feel: a welcome banner (MOTD), a `labhelp` quick-reference
# command, and a themed prompt shown on every interactive login. This is what
# makes attaching to the container feel like logging into a dedicated machine
# instead of a bare shell — see modules/module-03-password-attacks/console.env
# (SHELL_HOST) and scripts/lab-console (enter_shell). Run as root to write into
# /etc and /usr/local/bin, then drop back to the analyst user the base expects.
COPY motd /etc/motd-lab
COPY labhelp /usr/local/bin/labhelp
COPY lab-bashrc /tmp/lab-bashrc
# The unprivileged 'analyst' user must be able to read the MOTD and run labhelp,
# so set world-readable/executable modes explicitly (COPY otherwise preserves the
# source files' restrictive modes).
# Append to /etc/bash.bashrc for the system-wide banner, AND to the analyst
# user's own ~/.bashrc — the Kali base ships an analyst ~/.bashrc that sets its
# own PS1 and is sourced *after* /etc/bash.bashrc, so the themed prompt only wins
# if we also set it there (the MOTD-once guard keeps the banner from repeating).
RUN chmod 0644 /etc/motd-lab \
    && chmod 0755 /usr/local/bin/labhelp \
    && cat /tmp/lab-bashrc >> /etc/bash.bashrc \
    && cat /tmp/lab-bashrc >> /home/analyst/.bashrc \
    && rm /tmp/lab-bashrc

USER analyst
WORKDIR /home/analyst/lab
CMD ["sleep", "infinity"]
