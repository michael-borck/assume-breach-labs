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

## 2. Get the labs (no git needed)

Download the ZIP and unzip it — you'll get a folder called `assume-breach-labs-main`:

**https://github.com/michael-borck/assume-breach-labs/archive/refs/heads/main.zip**

> **Windows note:** "Extract All" puts the ZIP's contents inside a *new* folder named after the ZIP,
> so you end up with `assume-breach-labs-main\assume-breach-labs-main\`. That's normal — the **inner**
> folder (the one containing `start.bat`) is the one you want. Feel free to move it somewhere
> convenient (e.g. your Desktop) and delete the empty outer folder.

(If you do have git, `git clone https://github.com/michael-borck/assume-breach-labs.git` works too.)

## 3. Launch it

You start every lab the same way — the first run pulls the images it needs automatically.

- **macOS:** double-click **`start.command`** in the folder. First time, if macOS blocks it, right-click
  it → **Open** → **Open**. (Or in Terminal: `cd` into the folder and run `./start.sh`.)
- **Windows:** one-time, install [Git for Windows](https://git-scm.com/download/win) — it's the
  lab launcher (run the installer and click **Next** through every screen; the defaults are fine).
  Then open the unzipped folder — the **inner** one, containing `start.bat` — and double-click
  **`start.bat`**. If a window flashes open and vanishes: right-click an empty spot inside the
  folder → **Open in Terminal**, type `.\start.bat` and press Enter to see the message (it usually
  says Docker Desktop isn't running yet).
- **Linux:** open a terminal in the folder and run `./start.sh`.

> Double-clicking `start.sh` itself does **not** work (the file browser opens it in a text editor).
> Use `start.command` (Mac) / `start.bat` (Windows), or run `./start.sh` from a terminal.

> Offline or want to pre-fetch the shared toolbox image? Run `make pull-base` (or `make build-base` to
> build it locally; on an exFAT drive prefix with `DOCKER_BUILDKIT=0`).

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
