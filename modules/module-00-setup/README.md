# Module 00 — Environment Setup

Do this once, before your first lab. It replaces the old "install VirtualBox and copy the
Windows XP VM" step. There is no VM here — everything runs in Docker containers.

By the end you will have Docker working, the shared toolbox image pulled, and one lab started
and stopped again.

## 1. Install Docker

- **Windows / macOS:** install [Docker Desktop](https://www.docker.com/products/docker-desktop/)
  and start it. On Apple Silicon Macs it just works (the images are multi-arch).
- **Linux:** install Docker Engine + the Compose plugin from your distro or
  [docs.docker.com](https://docs.docker.com/engine/install/).

Check it works:

```bash
docker run --rm hello-world
docker compose version      # must be Compose v2 (the "docker compose" subcommand)
```

## 2. Get the labs

```bash
git clone https://github.com/michael-borck/assume-breach-labs.git
cd assume-breach-labs
```

## 3. Pull the toolbox image

Most modules share one toolbox image. Pull it once:

```bash
make pull-base
```

> Prefer to build it yourself (offline, or to see what's inside)? Run `make build-base`.
> On an external/exFAT drive on macOS, if the build errors on `._` files, use
> `DOCKER_BUILDKIT=0 make build-base`.

## 4. Smoke-test a lab

```bash
./start.sh       # on Windows: double-click start.bat, or `bash start.sh` in Git Bash
```

You should see a welcome banner, the machines powering on, and a `lab>` prompt. Type `help`, then
`quit` (answer `y` to shut down). If you got the `lab>` prompt, your environment is ready.

## 5. How a lab works

You drive labs from the **lab console** — you never type Docker commands.

- **Start:** `./start.sh` logs you in and powers on that module's machines.
- **Work:** at the `lab>` prompt, use plain commands — `ping pc2 pc1`, `rules load`, `connect pc3`.
  Type `help` for the list. Each command shows the real tool it runs, so you learn the real thing.
- **Follow** the module's `LAB-GUIDE.md` step by step.
- **Record** your answers/screenshots for the passport prompts at the end of each guide — that's
  what you submit for the lab journal.
- **Leave:** type `quit` (you'll be asked whether to shut the machines down).

> Curious what's underneath, or an instructor? The Makefile exposes the raw controls
> (`make m07`, `make status`, `make stop`), and each guide ends with an "Under the hood" section
> listing the real commands.

## Troubleshooting

| Symptom | Fix |
|---|---|
| `docker: command not found` | Docker isn't installed or Desktop isn't running. |
| `docker compose` says "not a docker command" | You have Compose v1. Install the v2 plugin. |
| Build fails with `xattr … operation not permitted` | exFAT drive — prefix with `DOCKER_BUILDKIT=0`. |
| A container exits immediately | Check logs: `docker logs <name>`. |
| Ports already in use | Another lab is still up — `make down` first. |
