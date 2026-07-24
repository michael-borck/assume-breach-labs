# Attacker workstation for Module 02. A thin layer on the shared toolbox image
# (which already has nmap + nc) so the student logs straight into a REAL shell
# here — root, with raw sockets — and scans the REAL lab network. No lab> verbs:
# real nmap on a real machine over a real network.
#
# The welcome banner (MOTD), a `labhelp` quick-reference and a themed prompt make
# attaching feel like logging into a dedicated pentest box. See
# modules/module-02-port-scanning/console.env (SHELL_HOST) and
# scripts/lab-console (enter_shell). The compose service still sets user: root +
# NET_RAW, which nmap's SYN/OS scans need.
FROM ghcr.io/michael-borck/assume-breach-base:latest

USER root
COPY motd /etc/motd-lab
COPY labhelp /usr/local/bin/labhelp
COPY lab-bashrc /tmp/lab-bashrc
# Explicit modes (the build context may carry restrictive perms that COPY keeps);
# theming appended to both /etc/bash.bashrc and root's ~/.bashrc so the banner
# and themed prompt win regardless of the base image's own bashrc.
RUN chmod 644 /etc/motd-lab \
    && chmod 755 /usr/local/bin/labhelp \
    && cat /tmp/lab-bashrc >> /etc/bash.bashrc \
    && cat /tmp/lab-bashrc >> /root/.bashrc \
    && rm /tmp/lab-bashrc

WORKDIR /root
CMD ["sleep", "infinity"]
