# Security Policy

## What this repository is

Assume Breach Labs is **teaching material for an introductory security unit**. It
ships containers that are *deliberately* vulnerable, *deliberately* over-privileged,
and full of weak credentials. That is the curriculum, not an oversight.

Run it on a machine you control. Do not deploy it on anything reachable from a
network you do not own.

## Reporting a vulnerability

Open an issue at
<https://github.com/michael-borck/assume-breach-labs/issues>, or email
<michael@borck.dev> if you would rather not report in public.

Please report:

- Anything that lets a lab container reach the **host** or the host's network when
  it should not.
- Anything that exposes a lab service **beyond `localhost`** by default.
- Supply-chain problems: workflow permissions, unpinned or compromised images or
  actions.

Please do **not** report the items in the next section. They are the exercises.

## Deliberate by design

These will look alarming to a scanner or a reviewer reading the repo out of
context. Each is required for a lab to teach what it teaches.

### Raised container privileges

| Where | Setting | Why it is required |
|---|---|---|
| `m02-attacker` | `user: root`, `cap_add: NET_RAW, NET_ADMIN` | nmap SYN scans (`-sS`) and OS detection (`-O`) craft raw packets. Without these the module's core tool cannot run. |
| `m07-firewall`, `m07-pc1`–`pc4` | `cap_add: NET_ADMIN`, `net.ipv4.ip_forward=1` | The lab *is* iptables. Students write and reorder rules on a container that routes between two networks. |
| `m11-client`, `m11-server`, `m11-eavesdropper` | `cap_add: NET_ADMIN, NET_RAW`, `net.ipv4.ip_forward=1` | The lab *is* traffic interception: capture a password in the clear, then watch WireGuard hide it. |
| `m06-wireshark` | `cap_add: NET_ADMIN` | Live packet capture on the container's own interface. |

### Weak secrets and crackable artefacts

Committed on purpose; secret scanners will flag them indefinitely.

- **`m03`** — MD5/NTLM hash files, `rockyou`-style wordlists, and an encrypted
  `secret.zip`. Chosen *because* they fall quickly to John the Ripper and
  `fcrackzip`. The point is to feel how fast a weak password dies.
- **`m11`** — WireGuard private keys in
  `modules/module-11-vpn/node/client-wg0.conf` and `server-wg0.conf`. Fixed keys
  so the tunnel comes up identically for every student. They protect nothing.
- **`m09`** — deliberately broken TLS certificates (expired, self-signed, wrong
  hostname), regenerated at every start so "expired" is genuinely expired.
- **`m06`** — the browser GUI's default credentials (`analyst` / `labpass`).
  Documented, not secret. Override with `LAB_GUI_USER` / `LAB_GUI_PASSWORD`.

### Vulnerable applications

- **`m10`** — OWASP Juice Shop, pinned to `v20.1.1`. Exploitable by design; that
  is the assignment.

## Hardening that IS in place

So that the above does not get mistaken for "nothing was considered".

**Nothing is reachable from outside the host.** Every published port binds
`127.0.0.1`, not `0.0.0.0`. Docker's short port syntax (`"3010:3000"`) binds all
interfaces, which would put Juice Shop and the Wireshark desktop in front of
everyone on a campus or cafe subnet. Students reach them over `localhost` either
way, so this costs nothing.

**The GUI requires a login.** The LinuxServer Wireshark image serves its desktop
*unauthenticated* unless `CUSTOM_USER` and `PASSWORD` are set. They are now set.

**The highest-risk containers have no route off their own network.** Modules
**01, 02, 03, 04 and 08** sit on `internal: true` networks — no NAT gateway, so no
internet and, more to the point, **no path onto the LAN the host is plugged into**.

This matters most for `m02-attacker`, which is root with nmap and hydra and would
otherwise have a live route to the university network, with scans appearing to
originate from the lab PC. Verified: from that container, `ping 1.1.1.1` returns
`Network is unreachable`, and `nmap -sn <campus /28>` fails with *"failed to
determine route"* — it cannot even construct a route — while `nmap -sS` against the
lab's own targets still works normally.

No module needs egress at runtime. Every `apt-get`/`pip install` runs at image
**build** time in CI; `m07`'s dnsmasq is `no-resolv`; and every external hostname
in the lab guides is either historical ("what this replaces") or an optional link
the student's own browser opens. The one exception is `m06`'s optional
`fetch-samples`, which downloads extra Wireshark sample captures on demand.

**Supply chain.** All third-party actions are pinned to commit SHAs. External
images are pinned to versions (`juice-shop:v20.1.1`, `nginx:1.31.3-alpine`,
`linuxserver/wireshark:4.6.6-r0-ls319`). `kalilinux/kali-rolling` is intentionally
left rolling — the toolbox image is rebuilt weekly to pick up tool updates. No
workflow uses `pull_request_target` or `workflow_run`, and no `pull_request`
trigger exists, so a fork cannot reach the GHCR publish job.

## Known limitations

Stated plainly rather than left for someone to discover.

1. **The browser-facing modules still have internet egress** (05, 06, 09, 10).
   Verified on Docker Desktop 28.4.0: `internal: true` **silently discards
   published ports** — the container comes up showing `3000/tcp` with no host
   mapping and no warning from Compose. A browser lab therefore cannot be isolated
   *and* reachable. These are locked down the other available ways instead:
   localhost-only binds, plus authentication on m06. m05, m09 and m10 are passive
   web servers with no student shell; m06 is the one with a shell, which is why it
   also got credentials.

2. **Modules 07 and 11 cannot be isolated either — for a different reason.**
   `internal: true` breaks routing *between* two lab networks, which is precisely
   what these two modules are. Docker implements internal networks with
   `! -s <subnet> -o <bridge> -j DROP`, so a packet from `m07-pc1` (10.1.1.2)
   toward the 10.1.2.0/24 bridge is dropped for having a foreign source address.
   The failure is quiet and nasty: containers all start, the firewall itself can
   reach both sides, but `pc1` cannot ping `pc4` and the lab is useless. Both
   modules are therefore deliberately left non-internal.

   These nodes are Debian with tcpdump/WireGuard rather than a full attack
   toolkit, and they hold `NET_ADMIN` by design — so any egress block applied
   *inside* the container is something a student can trivially undo. For these,
   the control belongs on the host, not in this file.

3. **`seccomp:unconfined` has been removed from `m06`.** Verified that the
   selkies/WebRTC GUI starts and serves correctly under the default seccomp
   profile on the pinned image tag. If a future base image regresses, restore
   `security_opt: ["seccomp:unconfined"]` — and note it here.

4. **Docker Desktop on Windows grants effective local Administrator.** Membership
   of the `docker-users` group is enough to bind-mount the host filesystem into a
   container as root (`docker run -v C:\:/host ...`). This is Docker Desktop's
   trust model, not something this repository can change, and **no setting in this
   compose file mitigates it.** On managed or shared machines, either accept it,
   constrain it with Docker Desktop Settings Management (bind-mount allow-lists
   plus Registry Access Management — requires a Business subscription with
   enforced sign-in), reimage between sessions, or keep Docker off the endpoint
   entirely and run the labs centrally. See `docs/SERVER-DEPLOYMENT.md`, which
   designs exactly that.

5. **Codespaces** runs the labs over a privileged docker-in-docker feature inside
   an ephemeral cloud VM. Acceptable there; it is not a model for a shared lab PC.
