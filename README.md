# Assume Breach — Labs

A self-contained, Docker-based lab series for a first course in **defensive information
security**.

**▶ Student front door: https://michael-borck.github.io/assume-breach-labs/** Every exercise runs in containers — no virtual machine, no Windows image, and (with
one small exception) no dependence on external websites. The practical companion to the
*Assume Breach* book.

> **Unit-agnostic by design.** Modules are numbered by topic, not by any unit code. See
> [`SCHEDULE.md`](SCHEDULE.md) to map modules onto a specific teaching week / workshop schedule.

## Quick start

You don't need to know Docker. Install Docker Desktop (see
[`modules/module-00-setup`](modules/module-00-setup/)), then:

```bash
./start.sh
```

(On Windows: double-click `start.bat`, or run `bash start.sh` in Git Bash.)

That "logs you in" to an immersive lab console — the machines power on and you drive the whole lab
with plain commands like `ping pc2 pc1` and `rules load`. No `docker` typing. Follow the module's
`LAB-GUIDE.md`. Type `quit` to leave.

> **Choosing a module:** `./start.sh` opens Module 07 by default. Pick another with
> `LAB_MODULE=07 ./start.sh`. Instructors can also use the Makefile directly (`make m07`,
> `make status`, `make help`).

## Modules

| Module | Topic | Runs | Guide |
|--------|-------|------|-------|
| [00](modules/module-00-setup/) | Environment setup (install Docker, smoke test) | docs | `module-00-setup/README.md` |
| **[01](modules/module-01-access-control/)** | **Access control & isolation (users, groups, permissions, ACLs)** | **ready** | `module-01-access-control/LAB-GUIDE.md` |
| **[02](modules/module-02-port-scanning/)** | **Port scanning & enumeration (nmap)** | **ready** | `module-02-port-scanning/LAB-GUIDE.md` |
| **[03](modules/module-03-password-attacks/)** | **Password attacks (John the Ripper, fcrackzip)** | **ready** | `module-03-password-attacks/LAB-GUIDE.md` |
| **[04](modules/module-04-cryptography/)** | **Cryptography (classic ciphers + real PGP/GnuPG)** | **ready** | `module-04-cryptography/LAB-GUIDE.md` |
| **[05](modules/module-05-risk/)** | **Risk management (in-browser SLE/ALE calculator)** | **ready** | `module-05-risk/LAB-GUIDE.md` |
| **[06](modules/module-06-packet-capture/)** | **Packet capture & analysis (Wireshark-in-browser)** | **ready** | `module-06-packet-capture/LAB-GUIDE.md` |
| **[07](modules/module-07-firewalls/)** | **Firewalls (real iptables/nftables)** | **ready** | `module-07-firewalls/LAB-GUIDE.md` |
| **[08](modules/module-08-forensics/)** | **Digital forensics (email headers + stylometry)** | **ready** | `module-08-forensics/LAB-GUIDE.md` |
| **[09](modules/module-09-human-factors/)** | **Human factors (self-hosted quiz + broken-cert sites)** | **ready** | `module-09-human-factors/LAB-GUIDE.md` |

Going further / extension labs for advanced students: [`GOING-FURTHER.md`](GOING-FURTHER.md).

## How it works

- **One `docker-compose.yml`.** Every service in the whole series lives in a single compose file.
  Each module is a Compose **profile**, so `make m07` (i.e. `docker compose --profile module-07 up
  -d`) starts *only* that module's containers. Nothing else runs.
- **Pull, don't build.** The shared toolbox image is published to GHCR
  (`ghcr.io/michael-borck/assume-breach-base`), so most modules start with a plain pull — no build
  toolchain needed on student laptops. Custom per-module images that aren't yet on GHCR build
  locally the first time.
- **Self-contained.** External web tools in the original labs are replaced by services running
  inside the compose network. The only remaining external links are two optional third-party
  awareness quizzes in Module 09.

### Building images locally instead of pulling

The published image is the default. To build the base image yourself (offline, or to customise
tools):

```bash
make build-base      # builds base.Dockerfile, tags it as the GHCR image name
```

> **Note for external/exFAT drives (macOS):** this drive writes AppleDouble `._*` sidecar files
> that break BuildKit's context transfer (`failed to xattr … operation not permitted`). If a
> local build fails that way, use the legacy builder: `DOCKER_BUILDKIT=0 make build-base`.

## Data & portability

The shipped labs use **no host bind mounts**, so they run identically on macOS, Windows, and Linux —
including from an external/exFAT drive. Two approaches carry lab data:

- **Small data** (hashes, wordlists, configs, small archives — under ~1 MB): **baked into the module
  image**. Negligible size, pulls cleanly from GHCR, zero mount issues.
- **Large data** (packet captures, disk/memory images, in later modules): a **named Docker volume
  populated at runtime**, never a host bind mount. Named volumes live inside Docker's own storage, so
  they sidestep host file-sharing quirks on every OS.

> **Developing on an external/exFAT drive (macOS)?** Docker Desktop's file-sharing can't bind-mount
> such paths and BuildKit trips on macOS `._*` sidecar files. This only affects *building here* — not
> students, who pull prebuilt images. Use `DOCKER_BUILDKIT=0` for local builds if one fails.

## Running where you can't install Docker

Most people run the labs locally (see above). For locked-down lab PCs, Chromebooks, or anywhere Docker
Desktop can't be installed, there are two online routes — in order of preference:

1. **A managed Linux + Docker desktop (recommended).** If your institution offers a Docker-capable
   Linux VM through a remote-desktop / VDI service, run the labs there exactly as you would locally —
   download the ZIP and run `./start.sh`. No personal accounts, IT-supported. Ask your unit coordinator
   whether this is available.

2. **GitHub Codespaces (personal fallback).** Opens the repo in a cloud VS Code in your browser and
   runs the same `./start.sh`, nothing installed on your machine. Open the repo on GitHub →
   **Code ▸ Codespaces ▸ Create codespace**, then run `./start.sh`. Know the trade-offs:
   - Needs a **GitHub account** (more free hours via [GitHub Education](https://education.github.com)).
   - You work inside VS Code in the browser, not the clean console front door.
   - The browser modules (5, 6, 9) open via a **forwarded URL** Codespaces provides, not `localhost` —
     the console detects Codespaces and prints the right link.
   - **Module 9's broken-certificate sites only work locally** — the Codespaces proxy presents its own
     valid certificate, which masks the broken ones the exercise relies on. The quiz half works online.

## Licence

MIT — see [`LICENSE`](LICENSE). Teaching material is free to reuse and adapt.
