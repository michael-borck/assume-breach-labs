#!/bin/sh
# Start a subset of services based on env, so each target has a distinct profile.
#   START_SSH=1                 -> OpenSSH on 22
#   START_FTP=1                 -> vsftpd (anonymous) on 21
#   START_HTTP=1 HTTP_PORT=80   -> a web server
#   START_BANNER=1 BANNER_PORT=9000 BANNER_TEXT="Custom-App 2.1" -> a mystery service
set -e

if [ "${START_SSH:-0}" = "1" ]; then
    ssh-keygen -A >/dev/null
    mkdir -p /run/sshd
    useradd -m -s /bin/bash serviceuser 2>/dev/null || true
    echo 'serviceuser:password123' | chpasswd
    sed -i 's/#\?PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
    /usr/sbin/sshd
    echo "[+] SSH listening on 22"
fi

if [ "${START_FTP:-0}" = "1" ]; then
    mkdir -p /srv/ftp /var/run/vsftpd/empty
    echo "Internal file server. Authorised access only." > /srv/ftp/README.txt
    cat > /etc/vsftpd.conf <<EOF
listen=YES
anonymous_enable=YES
anon_root=/srv/ftp
no_anon_password=YES
seccomp_sandbox=NO
secure_chroot_dir=/var/run/vsftpd/empty
EOF
    vsftpd /etc/vsftpd.conf &
    echo "[+] FTP listening on 21"
fi

if [ "${START_HTTP:-0}" = "1" ]; then
    PORT="${HTTP_PORT:-80}"
    mkdir -p /srv/www
    echo "<html><body><h1>${HTTP_TITLE:-Internal Server}</h1></body></html>" > /srv/www/index.html
    ( cd /srv/www && python3 -m http.server "$PORT" >/dev/null 2>&1 ) &
    echo "[+] HTTP listening on $PORT"
fi

if [ "${START_BANNER:-0}" = "1" ]; then
    python3 /banner.py "${BANNER_PORT:-9000}" "${BANNER_TEXT:-Custom-App 2.1}" &
    echo "[+] Banner service on ${BANNER_PORT:-9000}"
fi

echo "[*] Target $(hostname) ready."
exec sleep infinity
