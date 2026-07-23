# Access-control workstation for Module 01. A small Linux box where the student
# is the administrator (root) managing users, groups, and file permissions.
# Replaces the Windows-XP NTFS-permissions lab; same idea, real Linux tools.
FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
        acl \
        util-linux \
        coreutils \
        sudo \
    && rm -rf /var/lib/apt/lists/*

# Security-workstation feel: a welcome banner (MOTD), a `labhelp` quick-reference
# command, and a themed prompt shown on every interactive login. This is what
# makes attaching to the container feel like logging into a dedicated machine
# instead of a bare shell — see modules/module-01-access-control/console.env
# (SHELL_HOST) and scripts/lab-console (enter_shell).
COPY motd /etc/motd-lab
COPY labhelp /usr/local/bin/labhelp
COPY lab-bashrc /tmp/lab-bashrc
RUN chmod +x /usr/local/bin/labhelp \
    && cat /tmp/lab-bashrc >> /etc/bash.bashrc \
    && rm /tmp/lab-bashrc

# Three ordinary staff accounts. 'hr' group starts empty — the student populates it.
RUN useradd -m -s /bin/bash rico \
    && useradd -m -s /bin/bash jane \
    && useradd -m -s /bin/bash carlos \
    && groupadd hr

# The office fileshare: one confidential file (locked down) and one public notice.
RUN mkdir -p /office \
    && printf 'employee,role,salary\nA. Chen,CEO,485000\nR. Patel,CFO,310000\nyou,Analyst,68000\n' > /office/salaries.csv \
    && printf 'Reminder: the company picnic is this Friday. Everyone welcome!\n' > /office/notice.txt \
    && chown root:root /office/salaries.csv /office/notice.txt \
    && chmod 600 /office/salaries.csv \
    && chmod 644 /office/notice.txt

WORKDIR /office
CMD ["sleep", "infinity"]
