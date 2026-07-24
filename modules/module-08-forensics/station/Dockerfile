# Digital-forensics workstation for Module 08. Two offline Python tools:
# mailtrace (email header analysis) and stylometry (authorship attribution).
# Replaces the old lab's online header tools and the Windows 'Signature' app.
FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
        python3 ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN useradd -m -s /bin/bash analyst
COPY --chown=analyst:analyst data /home/analyst/lab
RUN chmod +x /home/analyst/lab/mailtrace.py /home/analyst/lab/stylometry.py \
    && ln -s /home/analyst/lab/mailtrace.py /usr/local/bin/mailtrace \
    && ln -s /home/analyst/lab/stylometry.py /usr/local/bin/stylometry \
    && chown -R analyst:analyst /home/analyst

# Security-workstation feel: a welcome banner (MOTD), a `labhelp` quick-reference
# command, and a themed prompt shown on every interactive login. This is what
# makes attaching to the container feel like logging into a dedicated forensic
# workstation instead of a bare shell — see modules/module-08-forensics/console.env
# (SHELL_HOST) and scripts/lab-console (enter_shell). Written as root (the base
# switches to USER analyst below), since these land in /etc and /usr/local/bin.
COPY motd /etc/motd-lab
COPY labhelp /usr/local/bin/labhelp
COPY lab-bashrc /tmp/lab-bashrc
# Explicit modes: the build context files may carry restrictive permissions that
# COPY preserves, so set them world-readable (analyst, a non-root user, must be
# able to read the MOTD and read+execute labhelp).
RUN chmod 644 /etc/motd-lab \
    && chmod 755 /usr/local/bin/labhelp \
    && cat /tmp/lab-bashrc >> /etc/bash.bashrc \
    && cat /tmp/lab-bashrc >> /home/analyst/.bashrc \
    && rm /tmp/lab-bashrc

USER analyst
WORKDIR /home/analyst/lab
CMD ["sleep", "infinity"]
