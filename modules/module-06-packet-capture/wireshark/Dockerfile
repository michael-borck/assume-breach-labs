# Module 06 — Wireshark in the browser (LinuxServer.io image, multi-arch amd64+arm64,
# web GUI on port 3000). Our own teaching captures are baked into /pcaps; a fetch
# helper can pull additional real-world captures on demand (see fetch-samples).
FROM lscr.io/linuxserver/wireshark:latest

# Our crafted teaching captures (freely redistributable — we made them).
COPY pcaps /pcaps
# On-demand downloader for external captures we link to but don't redistribute.
COPY fetch-samples.sh /usr/local/bin/fetch-samples
COPY samples.txt /pcaps/.samples.txt

# /pcaps must be readable by Wireshark and writable for downloaded samples.
RUN chmod +x /usr/local/bin/fetch-samples && chmod -R 0777 /pcaps
