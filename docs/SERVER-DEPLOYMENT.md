# Assume Breach Labs — Shared Server Deployment

Run the whole lab series for a class (40+ students) from **one Linux server** the
students reach with **only a browser** (or SSH) from the lab PCs. No Docker Desktop
on the endpoints, no per-student install, no cloud budget.

This is the "central lab host" design: each student gets a Linux account, runs the
labs under **rootless Podman** (so no student can see or collide with another's
containers), and reaches CLI labs through a browser terminal and the browser-based
labs through a reverse proxy.

> **Why this shape:** Docker Desktop was pulled from the Standard Operating
> Environment on security grounds; a VM appliance was rejected; free-tier Codespaces
> can't guarantee capacity for the summative exam. A single hardened server the lab
> PCs *connect into* keeps the risky runtime off every endpoint (the SOE only needs a
> browser/SSH client — already present) and gives guaranteed, controllable capacity
> for both labs and the exam.

---

## Contents

1. [Architecture](#1-architecture)
2. [Deployment target: dedicated box vs SOE image](#2-deployment-target)
3. [Server sizing](#3-server-sizing)
4. [Part A — Base server setup](#part-a--base-server-setup)
5. [Part B — Lab code changes](#part-b--lab-code-changes)
6. [Part C — Student accounts](#part-c--student-accounts)
7. [Part D — Browser access (web terminal + reverse proxy)](#part-d--browser-access)
8. [Part E — Security hardening](#part-e--security-hardening)
9. [Part F — Modules 07 & 11 under rootless](#part-f--modules-07--11-under-rootless)
10. [Part G — Load testing](#part-g--load-testing)
11. [Part H — Operations](#part-h--operations)

---

## 1. Architecture

```
  Lab PC (Windows SOE)                 Lab server (Linux)
  +------------------+                 +--------------------------------------+
  |                  |   HTTPS 443     |  Caddy (TLS, auth, per-seat routing) |
  |   Browser  ------+---------------->|    /term        -> ttyd (login)      |
  |                  |                 |    /u/<seat>/m06 -> 127.0.0.1:<port>  |
  +------------------+                 |    /u/<seat>/m10 -> 127.0.0.1:<port>  |
                                       +------------------+-------------------+
                                                          |
                                         per-student Linux accounts
                                         +----------------+----------------+
                                         | alice (uid 1001, seat 1)        |
                                         |   rootless Podman namespace     |
                                         |   m07-firewall, m07-pc1..4, ... |
                                         | bob   (uid 1002, seat 2)        |
                                         |   rootless Podman namespace     |
                                         |   ...isolated, own subnets...   |
                                         +---------------------------------+
                                         shared read-only image store
```

- **Isolation** comes from rootless Podman *per Linux user*: each student's containers
  and networks live in their own namespace, so the fixed container names (`m07-pc1`)
  and fixed subnets (`10.1.1.0/24`) in `docker-compose.yml` never collide between
  students.
- **CLI modules** (01, 02, 03, 04, 07, 08, 11): student logs into a shell (browser
  terminal or SSH) and runs `./start.sh`.
- **Browser modules** (05, 06, 09, 10): each student's container publishes a
  **unique host port** (derived from their seat number); Caddy maps a friendly URL to
  that port.

---

## 2. Deployment target

Two places this can land. **This document covers the dedicated server** (recommended),
but the lab-code changes in Part B apply to both.

| | Dedicated lab server (this doc) | Podman baked into the SOE image |
|---|---|---|
| Endpoint needs | browser / SSH client (already in SOE) | Podman + WSL2 in the image |
| IT ("DTS") ask | approve + host one server | add Podman to the nightly image |
| Nightly reimage | irrelevant (server is separate, persistent) | fine — image is rebuilt clean each night, which is *good* for a lab (clean slate) |
| Capacity for exam | guaranteed, you control it | depends on each PC |
| Blocked if DTS says "no local container engine at all" | **No** — nothing runs on the endpoint | **Yes** |

The nightly reboot/reimage cycle only matters for the SOE-image option; for the
dedicated server it changes nothing. If DTS *does* come to the party and adds Podman
to the image, students run the labs locally with the same Part B changes — but the
server remains the safer bet for the exam and for the case where DTS objects to any
endpoint runtime.

---

## 3. Server sizing

**Size for the heaviest single module the class runs at once, not the sum** — labs are
scheduled by week, so the whole class is on one module per session.

| Driver | Module | Concurrent load (40 students) |
|---|---|---|
| RAM | **06** Wireshark-in-browser | full Linux *desktop* per student, ~1.5 GB each → **~60 GB** |
| CPU | **03** password cracking | 40× hashcat/john saturate cores (bursty, short) |
| RAM (moderate) | **10** Juice Shop | ~300 MB each → ~12 GB |
| Container count | **07** firewalls | 6 containers × 40 = ~240 (light, mostly idle) |

**Recommended target for 40 students:** **32 cores / 64 GB RAM / 512 GB NVMe SSD.**
- Covers ten of the eleven modules comfortably.
- **Module 06 is the outlier** — 40 concurrent desktops want ~128 GB, *or* run it for
  smaller groups / staggered / as a lighter guided demo.

The bottleneck at ~200 containers is **kernel tunables, not hardware** (Part A.4).
Confirm real numbers with the load test in Part G before buying anything.

---

## Part A — Base server setup

Assumes a fresh **Ubuntu 22.04/24.04 LTS** (or RHEL/Rocky 9). Run as root/sudo.

### A.1 Install Podman + compose

```bash
# Ubuntu
apt-get update
apt-get install -y podman podman-compose uidmap slirp4netns fuse-overlayfs dbus-user-session
# 'podman compose' (v4+) will use podman-compose or docker-compose under the hood.
podman --version
```

Enable lingering so students' rootless Podman services survive logout (needed for
long-running lab containers):

```bash
# Applied per user in the provisioning script (Part C) via: loginctl enable-linger <user>
```

### A.2 Rootless prerequisites

```bash
# Give the subuid/subgid ranges rootless needs (provisioning script sets per-user;
# defaults in /etc/subuid and /etc/subgid are usually created by useradd).
# Verify the kernel allows unprivileged user namespaces:
sysctl kernel.unprivileged_userns_clone   # should be 1 (Debian/Ubuntu)
```

### A.3 Shared image store (critical for disk)

Rootless Podman stores images **per user** by default — 40 copies of the ~1.5 GB Kali
base is 60 GB of pure duplication. Configure a single read-only shared store that every
account layers on top of.

`/etc/containers/storage.conf` (system-wide):

```toml
[storage]
driver = "overlay"

[storage.options]
additionalimagestores = [
  "/var/lib/shared-images",
]
```

Populate it once as admin, then make it read-only:

```bash
mkdir -p /var/lib/shared-images
# Pre-pull every image the labs use into the shared store:
podman --root /var/lib/shared-images pull ghcr.io/michael-borck/assume-breach-base:latest
podman --root /var/lib/shared-images pull ghcr.io/michael-borck/assume-breach-node:latest
podman --root /var/lib/shared-images pull ghcr.io/michael-borck/assume-breach-vpn:latest
podman --root /var/lib/shared-images pull ghcr.io/michael-borck/assume-breach-target:latest
podman --root /var/lib/shared-images pull ghcr.io/michael-borck/assume-breach-wireshark:latest
podman --root /var/lib/shared-images pull ghcr.io/michael-borck/assume-breach-quiz:latest
podman --root /var/lib/shared-images pull ghcr.io/michael-borck/assume-breach-badcerts:latest
podman --root /var/lib/shared-images pull ghcr.io/michael-borck/assume-breach-riskcalc:latest
podman --root /var/lib/shared-images pull ghcr.io/michael-borck/assume-breach-accesslab:latest
podman --root /var/lib/shared-images pull ghcr.io/michael-borck/assume-breach-cracking:latest
podman --root /var/lib/shared-images pull ghcr.io/michael-borck/assume-breach-crypto:latest
podman --root /var/lib/shared-images pull ghcr.io/michael-borck/assume-breach-forensics:latest
podman --root /var/lib/shared-images pull nginx:alpine
podman --root /var/lib/shared-images pull bkimminich/juice-shop:latest
chmod -R a+rX /var/lib/shared-images
```

Students' `podman compose pull` will then find the base images locally and only store
their own thin container layers. **Re-run these pulls at the start of term** to pick up
image updates.

### A.4 Kernel tuning — the real capacity limit

At ~200 containers you hit these long before RAM/CPU. Drop in
`/etc/sysctl.d/99-assume-breach-labs.conf`:

```ini
# inotify — containers consume instances/watches quickly
fs.inotify.max_user_instances = 8192
fs.inotify.max_user_watches   = 1048576

# process IDs — 40 users x many container processes
kernel.pid_max = 4194304

# file descriptors
fs.file-max = 2097152

# ARP / neighbour table — many containers on bridges overflow the defaults,
# which shows up as random "host unreachable" in module 07
net.ipv4.neigh.default.gc_thresh1 = 4096
net.ipv4.neigh.default.gc_thresh2 = 8192
net.ipv4.neigh.default.gc_thresh3 = 16384

# connection tracking — module 07 is a firewall lab
net.netfilter.nf_conntrack_max = 524288

# rootless needs plenty of user namespaces
user.max_user_namespaces = 63000
```

Apply: `sysctl --system`

Per-user process/FD limits — `/etc/security/limits.d/99-labs.conf`:

```
@students   soft   nofile   65536
@students   hard   nofile   65536
@students   soft   nproc    16384
@students   hard   nproc    16384
```

And raise systemd's per-user task cap (`/etc/systemd/system.conf.d/labs.conf`):

```ini
[Manager]
DefaultTasksMax=infinity
```

`systemctl daemon-reexec` after changing that.

---

## Part B — Lab code changes

Three small changes to the repo. All are backward-compatible: Docker stays the default,
so nothing changes for anyone still using Docker Desktop.

### B.1 Make `lab-console` engine-agnostic (`CONTAINER_ENGINE`)

`scripts/lab-console` hardcodes `docker`. Add near the top (after `PROJECT_ROOT=...`):

```bash
# Container engine — defaults to docker; set CONTAINER_ENGINE=podman on the lab server.
ENGINE="${CONTAINER_ENGINE:-docker}"
COMPOSE_CMD="${COMPOSE_CMD:-$ENGINE compose}"
```

Then replace throughout the file:

| Old | New |
|---|---|
| `docker exec ...` | `$ENGINE exec ...` |
| `docker ps -q ...` | `$ENGINE ps -q ...` |
| `docker info` | `$ENGINE info` |
| `command -v docker` | `command -v "$ENGINE"` |
| `docker compose ...` | `$COMPOSE_CMD ...` |

Update the `need_docker()` message so it names the right engine:

```bash
need_docker() {
    if ! command -v "$ENGINE" >/dev/null 2>&1; then
        printf "${C_ERR}%s is not installed.${NC}\n" "$ENGINE"; exit 1
    fi
    if ! $ENGINE info >/dev/null 2>&1; then
        printf "${C_ERR}%s is not running.${NC}\n" "$ENGINE"; exit 1
    fi
}
```

On the server, students' shells get `export CONTAINER_ENGINE=podman` (set globally in
Part C), so `./start.sh` "just works" against Podman.

The `Makefile` is already engine-agnostic (`COMPOSE ?= docker compose`), so
`make m07 COMPOSE="podman compose"` needs no change.

### B.2 Parameterize the browser-module ports in `docker-compose.yml`

Only the four browser modules publish ports. Make each port an overridable variable so
every student can bind a unique host port:

```yaml
# m05-web
    ports:
      - "${M05_PORT:-8055}:80"

# m06-wireshark
    ports:
      - "${M06_PORT:-3006}:3000"

# m09-quiz
    ports:
      - "${M09_QUIZ_PORT:-8090}:80"

# m09-certs
    ports:
      - "${M09_CERT1_PORT:-8443}:8443"
      - "${M09_CERT2_PORT:-8444}:8444"
      - "${M09_CERT3_PORT:-8445}:8445"

# m10-web
    ports:
      - "${M10_PORT:-3010}:3000"
```

The `:-8055` defaults keep single-user Docker behaviour identical.

### B.3 Per-seat ports + URL in `lab-console`

Give each student a **seat number** and derive a contiguous block of ports from it.
Add to `lab-console` after the engine lines:

```bash
# Per-seat port block so many students share one host without colliding.
# Seat comes from the account's UID (accounts start at 1001 => seat 1..N).
SEAT="${LAB_SEAT:-$(( $(id -u) - 1000 ))}"
[ "$SEAT" -ge 1 ] 2>/dev/null || SEAT=0
PORT_BASE=$(( 20000 + SEAT * 10 ))
export M05_PORT=$((PORT_BASE+0))  M06_PORT=$((PORT_BASE+1))
export M09_QUIZ_PORT=$((PORT_BASE+2)) M09_CERT1_PORT=$((PORT_BASE+3))
export M09_CERT2_PORT=$((PORT_BASE+4)) M09_CERT3_PORT=$((PORT_BASE+5))
export M10_PORT=$((PORT_BASE+6))

# Where students reach the server in a browser (host or reverse-proxy base).
LAB_HOST="${LAB_HOST:-localhost}"
```

Then rewrite the module's `BROWSER_URL` (currently `http://localhost:<default>`) to the
student's real URL. After `. "$DESC"` (which sources `console.env`), add:

```bash
# Remap the module's advertised browser URL to this student's host + seat port.
if [ -n "${BROWSER_URL:-}" ]; then
    case "$MODULE_NO" in
        05) _p=$M05_PORT ;; 06) _p=$M06_PORT ;;
        09) _p=$M09_QUIZ_PORT ;; 10) _p=$M10_PORT ;;
        *)  _p="" ;;
    esac
    if [ -n "$_p" ]; then
        if [ -n "${LAB_PROXY_BASE:-}" ]; then
            # Tier 2: friendly proxied URL, e.g. https://labbox/u/7/m06/
            BROWSER_URL="${LAB_PROXY_BASE}/u/${SEAT}/m${MODULE_NO}/"
        else
            # Tier 1: direct host:port
            BROWSER_URL="http://${LAB_HOST}:${_p}/"
        fi
    fi
fi
```

Keep the existing Codespaces block below it (harmless — guarded by `$CODESPACES`).

---

## Part C — Student accounts

For a class of ~40, **batch-provision from the enrolment roster** — don't build open
self-registration onto a shell server (that re-creates the security objection). SSO is
the "grown-up" upgrade later (see Part E).

### C.1 Put the repo where every account gets it

Clone once into the skeleton so each new account already has the labs:

```bash
git clone https://github.com/michael-borck/assume-breach-labs.git /etc/skel/assume-breach-labs
# (Apply the Part B changes to this copy so all students inherit them.)
```

Global engine + browser host for all students — `/etc/profile.d/lab-env.sh`:

```bash
export CONTAINER_ENGINE=podman
export LAB_HOST="labbox.your-uni.edu.au"      # the server's campus hostname
# For Tier 2 reverse proxy, also: export LAB_PROXY_BASE="https://labbox.your-uni.edu.au"
```

### C.2 Provisioning script

`provision-students.sh` — reads `roster.csv` (`username,fullname`), creates accounts,
sets random passwords, enables lingering, and emits credentials + a Caddy route block
per seat.

```bash
#!/usr/bin/env bash
set -euo pipefail
ROSTER="${1:-roster.csv}"
CREDS_OUT="credentials.csv"
CADDY_OUT="/etc/caddy/seats.d"      # imported by the Caddyfile (Part D)
mkdir -p "$CADDY_OUT"
echo "username,password,seat" > "$CREDS_OUT"

seat=0
while IFS=, read -r username fullname; do
    [ -n "$username" ] || continue
    seat=$((seat+1))
    if ! id "$username" >/dev/null 2>&1; then
        useradd -m -s /bin/bash -c "$fullname" -G students "$username"
    fi
    pass="$(openssl rand -base64 12)"
    echo "$username:$pass" | chpasswd
    loginctl enable-linger "$username"

    base=$(( 20000 + seat * 10 ))
    # Per-seat Caddy routes for the browser modules (Tier 2)
    cat > "$CADDY_OUT/seat-$seat.caddy" <<EOF
handle_path /u/$seat/m05/* { reverse_proxy 127.0.0.1:$((base+0)) }
handle_path /u/$seat/m06/* { reverse_proxy 127.0.0.1:$((base+1)) }
handle_path /u/$seat/m09/* { reverse_proxy 127.0.0.1:$((base+2)) }
handle_path /u/$seat/m10/* { reverse_proxy 127.0.0.1:$((base+6)) }
EOF
    echo "$username,$pass,$seat" >> "$CREDS_OUT"
done < "$ROSTER"

echo "Provisioned $seat accounts. Credentials in $CREDS_OUT. Reload Caddy."
```

> The `LAB_SEAT` in `lab-console` derives from UID (`uid - 1000`). If your `useradd`
> UIDs don't start at 1001, set `LAB_SEAT` explicitly per user (e.g. append
> `export LAB_SEAT=<n>` to their `~/.bashrc` in the loop) so ports match the Caddy
> routes above.

---

## Part D — Browser access

Two tiers. **Tier 1 gets you running today**; **Tier 2 is the version to run for a real
cohort** (TLS, clean URLs, one login).

### D.1 Web terminal (ttyd)

Gives students a shell in a browser tab — the SOE PC needs only a browser, no SSH client.

```bash
apt-get install -y ttyd
```

`/etc/systemd/system/ttyd.service`:

```ini
[Unit]
Description=ttyd web terminal (lab login)
After=network.target

[Service]
# 'login' presents a normal Linux login prompt; students use their provisioned account.
ExecStart=/usr/bin/ttyd -p 7681 -i 127.0.0.1 --writable login
Restart=always

[Install]
WantedBy=multi-user.target
```

```bash
systemctl enable --now ttyd
```

Bind to `127.0.0.1` only — it is exposed to students **through Caddy with TLS**, never
directly.

> **Heavier alternative — Apache Guacamole:** if you want session recording/auditing and
> central connection management (which strengthens the DTS security case), run Guacamole
> instead of ttyd. It's more to set up but gives per-session logs.

### D.2 Reverse proxy (Caddy) — Tier 2

One front door on 443: TLS, the web terminal, and each student's browser-lab ports.

```bash
apt-get install -y caddy
```

`/etc/caddy/Caddyfile`:

```
labbox.your-uni.edu.au {
    # Automatic HTTPS. On a campus-internal name, use 'tls internal' or point at
    # your institutional CA instead of public ACME.
    tls internal

    # Web terminal
    handle /term* {
        reverse_proxy 127.0.0.1:7681
    }

    # Per-seat lab routes generated by the provisioning script
    import /etc/caddy/seats.d/*.caddy

    # Everything else -> a simple landing page
    handle {
        respond "Assume Breach Labs. Go to /term to log in." 200
    }
}
```

```bash
systemctl reload caddy
```

Students then use **one URL**: `https://labbox.your-uni.edu.au/term` to log in and work;
`lab-console` prints the correct `https://.../u/<seat>/m06/` link when they start a
browser module.

### D.3 Tier 1 fallback (no proxy)

Skip Caddy, expose ttyd/ports directly on the campus network, and let `lab-console`
print `http://labbox:<seatport>/`. Functional for a pilot; **no TLS and many open
ports**, so move to Tier 2 before running the whole class — especially because of
Juice Shop (Part E).

---

## Part E — Security hardening

This server runs student-controlled containers and (module 10) **40 copies of a
deliberately vulnerable app (OWASP Juice Shop)**. Treat it accordingly.

1. **Campus-only.** Bind everything to the internal network / require VPN. Do **not**
   expose the server (or any lab port) to the public internet. 40 intentionally
   exploitable web apps on a public host is an attractive target.
2. **TLS + auth at the front door** (Tier 2). The reverse proxy is the single place to
   enforce HTTPS and, ideally, authentication. For real auth, front Caddy with your
   institution's **SSO** (`oauth2-proxy` against the Curtin IdP, or Guacamole's SSO) so
   students use existing credentials and there are no shared passwords to leak. This is
   the self-registration answer that DTS will actually approve.
3. **Rootless already isolates students** from each other's containers — keep it that
   way (don't be tempted into a shared rootful daemon to simplify networking).
4. **Firewall the host:** allow 443 (Caddy) and SSH from admin ranges only; block direct
   access to the 20000+ seat ports and 7681 from the network (Caddy reaches them on
   loopback).
5. **Quotas:** set disk quotas on `/home` so one student can't fill the box; the shared
   image store keeps image disk off the per-user budget.

---

## Part F — Modules 07 & 11 under rootless

These two need kernel-level networking that rootless restricts — **validate them before
relying on them:**

- **Module 07 (firewalls):** entrypoints enable `net.ipv4.ip_forward` and load iptables.
  `ip_forward` is per-network-namespace, so it is usually settable inside a rootless
  container that has `NET_ADMIN` in its user namespace — but test it.
- **Module 11 (VPN):** WireGuard needs `NET_ADMIN` and `/dev/net/tun`.
- **Module 02 (nmap):** SYN/OS scans need `NET_RAW` / raw sockets.

If any fail under rootless, the levers (least- to most-invasive):

1. Allow the needed sysctls by default in `/etc/containers/containers.conf`:
   ```toml
   [containers]
   default_sysctls = ["net.ipv4.ip_forward=1"]
   ```
2. Ensure the compose `cap_add` (`NET_ADMIN`, `NET_RAW`) survives rootless — they do,
   but the kernel must permit the operation.
3. Expose `/dev/net/tun` to the module-11 containers if WireGuard can't create the
   device.
4. **Last resort:** run only these two modules via a dedicated rootful path, keeping the
   other nine rootless.

Test recipe (run as a student account):

```bash
CONTAINER_ENGINE=podman LAB_MODULE=07 ./start.sh   # then: connect pc1; ping pc2; rules load
CONTAINER_ENGINE=podman LAB_MODULE=11 ./start.sh   # then verify the WireGuard tunnel comes up
CONTAINER_ENGINE=podman LAB_MODULE=02 ./start.sh   # then: nmap a target (SYN scan)
```

---

## Part G — Load testing

Get **real** numbers before committing hardware. This spins up N test accounts running
one module concurrently and reports peak RAM/CPU and any kernel-limit errors.

`load-test.sh`:

```bash
#!/usr/bin/env bash
# Usage: sudo ./load-test.sh <module-NN> <count>
set -euo pipefail
MOD="${1:?module e.g. 06}"; N="${2:?count e.g. 10}"
REPO="/etc/skel/assume-breach-labs"

echo "Spinning up $N concurrent students on module $MOD..."
for i in $(seq 1 "$N"); do
    u="loadtest$i"
    id "$u" >/dev/null 2>&1 || useradd -m -s /bin/bash -G students "$u"
    loginctl enable-linger "$u" >/dev/null 2>&1 || true
    sudo -u "$u" -H bash -lc \
        "cp -rn $REPO ~/lab 2>/dev/null; cd ~/lab && \
         CONTAINER_ENGINE=podman LAB_SEAT=$((900+i)) LAB_MODULE=$MOD ./start.sh '' \
         >/tmp/lt-$u.log 2>&1" &
done
wait
sleep 20

echo "=== Peak snapshot ==="
free -h
echo "load average: $(cat /proc/loadavg)"
echo "containers running: $(podman --root /var/lib/shared-images ps 2>/dev/null | wc -l) (shared store only; per-user counts differ)"
echo "=== Kernel-limit warnings (the real ceiling) ==="
dmesg | tail -50 | grep -Ei 'inotify|namespace|cannot fork|too many|neighbour table|nf_conntrack' || echo "  none — good"

echo
echo "Multiply this snapshot's RAM delta by (class size / $N) to project full load."
echo "Tear down with:  for i in \$(seq 1 $N); do userdel -r loadtest\$i; done"
```

Run the two heaviest first — `sudo ./load-test.sh 06 10` and `sudo ./load-test.sh 03 10`
— then multiply by (40/10). Watch `dmesg` as closely as `free`: at this scale a kernel
limit, not RAM, is the usual first failure.

---

## Part H — Operations

- **Start of term:** re-pull images into the shared store (A.3); run
  `provision-students.sh roster.csv`; hand out `credentials.csv`; `systemctl reload caddy`.
- **Before each session:** nothing — students bring their own module up with `./start.sh`.
- **Reclaim resources between weeks:** students leave a module with `quit` (it offers to
  stop). To force-clean everyone: as admin loop `sudo -u <user> podman stop -a` /
  `podman pod rm -a` across the class, or reboot the server out of hours.
- **Exam:** because capacity is yours to control, pre-stage the exam module in the shared
  store and confirm headroom with the load test at expected concurrency. No per-student
  quota can run out mid-exam.
- **End of term:** `userdel -r` the student accounts (or keep for resits); prune images.

---

## Quick reference — what to change in the repo

| File | Change | Section |
|---|---|---|
| `scripts/lab-console` | `CONTAINER_ENGINE`/`COMPOSE_CMD` vars; per-seat ports; URL remap | B.1, B.3 |
| `docker-compose.yml` | wrap the 4 browser modules' ports in `${..:-default}` | B.2 |
| `Makefile` | none (already `COMPOSE ?=`) | B.1 |

Everything else (kernel tuning, shared store, accounts, ttyd, Caddy, load test) lives on
the **server**, not in the repo.
```
