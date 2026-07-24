# Cryptography workstation for Module 04. Built on the shared base image (which
# has GnuPG and Python). Baked-in data: the classic-cipher tool, a ciphertext
# challenge, and the PGP keygen helper (~a few KB; no bind mounts).
#
# Shell mode: the student logs straight into this container as a real interactive
# shell (analyst on 'station') and runs the genuine crypto tools — cipher, gpg.
# A welcome banner (MOTD), a `labhelp` quick-reference command, and a themed
# prompt are shown on every interactive login, so attaching feels like logging
# into a dedicated workstation. See modules/module-04-cryptography/console.env
# (SHELL_HOST) and scripts/lab-console (enter_shell).
FROM ghcr.io/michael-borck/assume-breach-base:latest

USER root
COPY --chown=analyst:analyst data /home/analyst/lab
RUN chmod +x /home/analyst/lab/cipher.py /home/analyst/lab/make-keys.sh \
    && ln -s /home/analyst/lab/cipher.py /usr/local/bin/cipher \
    && chown -R analyst:analyst /home/analyst

# Security-workstation feel: welcome banner, labhelp command, themed prompt.
COPY motd /etc/motd-lab
COPY labhelp /usr/local/bin/labhelp
COPY lab-bashrc /tmp/lab-bashrc
RUN chmod 644 /etc/motd-lab \
    && chmod 755 /usr/local/bin/labhelp \
    && cat /tmp/lab-bashrc >> /etc/bash.bashrc \
    && cat /tmp/lab-bashrc >> /home/analyst/.bashrc \
    && rm /tmp/lab-bashrc

USER analyst
WORKDIR /home/analyst/lab
CMD ["sleep", "infinity"]
