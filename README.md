# Assume Breach — Labs

A self-contained, Docker-based lab series for a first course in **defensive information
security**. Every exercise runs in containers — no virtual machine, no Windows image, and (with
one small exception) no dependence on external websites. The practical companion to the
*Assume Breach* book.

> **Unit-agnostic by design.** Modules are numbered by topic, not by any unit code. See
> [`SCHEDULE.md`](SCHEDULE.md) to map modules onto a specific teaching week / workshop schedule.

## Quick start

```bash
# 1. Install Docker Desktop (or Docker Engine + Compose v2). See modules/module-00-setup.
# 2. Pull the shared toolbox image (or build it locally — see below).
make pull-base
# 3. Start a module (example: the firewall lab).
make m07
# 4. Read that module's guide and work through it.
#    modules/module-07-firewalls/LAB-GUIDE.md
# 5. Stop everything when done.
make stop
```

Run `make status` to see which modules are ready, and `make help` for all targets.

## Modules

| Module | Topic | Runs | Guide |
|--------|-------|------|-------|
| [00](modules/module-00-setup/) | Environment setup (install Docker, smoke test) | docs | `module-00-setup/README.md` |
| 01 | Access control & isolation | *planned* | — |
| 02 | Port scanning & enumeration | *planned* | — |
| 03 | Password attacks | *planned* | — |
| 04 | Cryptography | *planned* | — |
| 05 | Risk management (in-browser calculator) | *planned* | — |
| 06 | Packet capture & analysis (Wireshark-in-browser) | *planned* | — |
| **[07](modules/module-07-firewalls/)** | **Firewalls (real iptables/nftables)** | **ready** | `module-07-firewalls/LAB-GUIDE.md` |
| 08 | Digital forensics (email headers + stylometry) | *planned* | — |
| 09 | Human factors (self-hosted quizzes + broken-cert site) | *planned* | — |

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

## Licence

MIT — see [`LICENSE`](LICENSE). Teaching material is free to reuse and adapt.
