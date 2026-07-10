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
make status      # see which modules are ready
make m07         # start the firewall lab
docker ps        # you should see the m07-* containers running
make stop        # stop them again
```

If `docker ps` shows the containers, your environment is ready.

## 5. How a lab works

- **Start** a module with `make mNN` (e.g. `make m07`). It brings up only that module's containers.
- **Enter** a container to work in it:
  ```bash
  docker exec -it m07-pc1 bash      # or sh, depending on the image
  ```
- **Read** that module's `LAB-GUIDE.md` and follow the steps.
- **Record** your answers/screenshots for the passport prompts at the end of each guide — those
  are what you submit for the lab journal.
- **Stop** with `make stop`, or fully clean up with `make down`.

## Troubleshooting

| Symptom | Fix |
|---|---|
| `docker: command not found` | Docker isn't installed or Desktop isn't running. |
| `docker compose` says "not a docker command" | You have Compose v1. Install the v2 plugin. |
| Build fails with `xattr … operation not permitted` | exFAT drive — prefix with `DOCKER_BUILDKIT=0`. |
| A container exits immediately | Check logs: `docker logs <name>`. |
| Ports already in use | Another lab is still up — `make down` first. |
