# Module 00 — Environment Setup (Docker install & troubleshooting)

Do this once, before your first lab. It replaces the old "install VirtualBox and copy the
Windows XP VM" step. There is no VM here — everything runs in Docker containers.

By the end you will have Docker working, the shared toolbox image pulled, and one lab started
and stopped again. Budget about 20 minutes, most of it waiting for downloads.

> **You do not have to use your own laptop.** The lab machines already have everything
> installed. This guide is for people who want the labs on their own computer as well —
> handy, but never required.

## Before you start

- **Disk space:** about 10 GB free. The lab images are big; you download them once.
- **Memory:** 8 GB RAM is comfortable, 4 GB works for most labs.
- **Network:** the first launch downloads roughly a gigabyte. On campus wifi that can take
  several minutes and looks like nothing is happening. Let it finish.
- **Admin rights:** you need to be able to install software on the machine. On a locked-down
  work or family computer, use the lab machines instead.

## 1. Install Docker

Docker is free for study and personal use. You want **Docker Desktop** on Windows and macOS,
and **Docker Engine** on Linux — they are different products, so pick the right one.

### Windows

1. Download **[Docker Desktop for Windows](https://www.docker.com/products/docker-desktop/)**
   and run the installer. Accept the defaults — in particular, leave **"Use WSL 2"** ticked.
2. Restart when it asks you to.
3. Start Docker Desktop from the Start menu and wait until the whale icon in the system tray
   stops animating and the window says **running**. The first start takes a minute or two.

If the installer or Docker Desktop complains about **WSL 2**, **virtualisation**, or **Hyper-V**,
go to **section 2, "Windows only: turning on virtualisation"**, below — that's the one genuinely
fiddly step, and it only affects some laptops.

### macOS

Download **[Docker Desktop for Mac](https://www.docker.com/products/docker-desktop/)**, choosing
the **Apple Silicon** build for an M-series Mac or the **Intel** build for an older one. Drag it
to Applications, start it, and wait for *running*.

Nothing else to configure. Macs have virtualisation built into the operating system, so there is
no equivalent of the Windows firmware step.

### Linux

Install **Docker Engine** plus the **Compose plugin** from your distribution's packages or from
[docs.docker.com/engine/install](https://docs.docker.com/engine/install/). Docker Desktop for
Linux also exists, but Engine is simpler and is what these labs assume.

Then let your user talk to Docker without `sudo`:

```bash
sudo usermod -aG docker $USER
```

**Log out and back in** for that to take effect — opening a new terminal is not enough.

> Worth knowing, given what this unit is about: adding yourself to the `docker` group is
> effectively granting yourself administrator rights, because anyone who can start a container
> can mount the whole filesystem into it. That is fine on your own machine, but hold the
> thought — it is exactly the kind of privilege escalation you will hunt for in the
> access-control lab.

### Check it worked

Open a terminal (**PowerShell** on Windows, **Terminal** on macOS/Linux) and run:

```bash
docker run --rm hello-world
docker compose version      # must be Compose v2 — the "docker compose" subcommand
```

The first prints a friendly "Hello from Docker!" paragraph. If both work, skip to step 3.

## 2. Windows only: turning on virtualisation

Docker runs Linux containers, which needs your CPU's virtualisation feature switched on. On most
modern laptops it already is — try installing Docker first and only come here if it complains.

### Check whether it's already on

Press **Ctrl+Shift+Esc** for Task Manager → **Performance** → **CPU**. Look for
**Virtualisation** at the bottom right.

- **Enabled** → the hardware is fine. Any remaining error is about WSL, so do part (a) below.
- **Disabled** → do part (b).

### (a) Install or repair WSL 2

WSL (Windows Subsystem for Linux) is what Docker Desktop runs containers inside. Open
**PowerShell as administrator** (right-click the Start button → *Terminal (Admin)*) and run:

```powershell
wsl --install
wsl --update
```

Restart, start Docker Desktop, and try `docker run --rm hello-world` again. This works on
Windows 10 (version 2004 or later) and Windows 11, Home or Pro — you do **not** need Windows Pro,
and you do **not** need Hyper-V when using WSL 2.

### (b) Switch virtualisation on in the firmware

This one means restarting into your laptop's firmware settings (BIOS/UEFI) — the settings screen
that appears before Windows loads.

1. **Settings** → **System** → **Recovery** → **Advanced startup** → **Restart now**.
2. After the restart: **Troubleshoot** → **Advanced options** → **UEFI Firmware Settings** →
   **Restart**.
3. In the firmware menus, look under **Advanced**, **CPU Configuration**, **Security**, or
   **Configuration** for one of:
   - **Intel Virtualization Technology** / **Intel VT-x** (Intel CPUs)
   - **SVM Mode** / **AMD-V** (AMD CPUs)
4. Set it to **Enabled**.
5. Save and exit — usually **F10**, then confirm. Windows will boot normally.

> **Change only that one setting.** Everything else in there controls how the machine boots, and
> a wrong change can stop it starting. If you can't find the setting, don't go hunting through
> menus — bring the laptop to the lab and we'll look together.

If step 1 doesn't get you there, you can also press a key repeatedly as the machine starts:
**F2** (Dell, ASUS, Acer), **F10** or **Esc** (HP), **F1**/**F2** or the small **Novo** button
(Lenovo). It varies by model; searching "*<your laptop model>* enable virtualisation" usually
finds the exact screen.

**If the firmware is password-protected** — common on employer-managed or school-issued laptops —
you cannot change it, and that is not something to work around. Use the lab machines in 402.211;
they are set up and ready.

## 3. Get the labs (no git needed)

Download the ZIP and unzip it — you'll get a folder called `assume-breach-labs-main`:

**https://github.com/michael-borck/assume-breach-labs/archive/refs/heads/main.zip**

> **Windows note:** "Extract All" puts the ZIP's contents inside a *new* folder named after the ZIP,
> so you end up with `assume-breach-labs-main\assume-breach-labs-main\`. That's normal — the **inner**
> folder (the one containing `start.bat`) is the one you want. Feel free to move it somewhere
> convenient (e.g. your Desktop) and delete the empty outer folder.

(If you do have git, `git clone https://github.com/michael-borck/assume-breach-labs.git` works too.)

## 4. Launch it

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

## 5. Smoke-test a lab

```bash
./start.sh       # on Windows: double-click start.bat, or `bash start.sh` in Git Bash
```

Pick module `01`. You should see a welcome banner with the **lab pack version** under it, the machines
powering on, and then a root shell on the workstation:

```
root@station:/office#
```

Type `labhelp` to see what the machine is for, then `exit` (answer `y` to shut the machines down). If
you got that prompt, your environment is ready.

> Most modules log you straight into a real machine like this. A few (05, 06, 09, 10) are browser- or
> console-driven and give you a `lab>` prompt instead — type `help` there for that module's commands.

## 6. How a lab works

You start every lab the same way — you never type Docker commands.

- **Start:** `./start.sh` logs you in and powers on that module's machines.
- **Work:** most modules drop you into a **real shell** on a lab machine (`root@station:/office#`),
  where you run genuine Linux and security tools — `chmod`, `nmap`, `john`, `tcpdump`. Type `labhelp`
  for the mission and a starter set of commands. Because the commands and error messages are real,
  an AI assistant can help you when you get stuck. The browser/console modules (05, 06, 09, 10) give
  you a `lab>` prompt instead; type `help` there.
- **Follow** the module's `LAB-GUIDE.md` step by step.
- **Record** your answers/screenshots for the passport prompts at the end of each guide — that's
  what you submit for the lab journal.
- **Leave:** type `exit` (or `quit` at a `lab>` prompt). You'll be asked whether to shut the machines
  down — answering `n` makes the next launch faster.

> Curious what's underneath, or an instructor? The Makefile exposes the raw controls
> (`make m07`, `make status`, `make stop`), and each guide ends with an "Under the hood" section
> listing the real commands.

## If it doesn't work

**Check these three things first — they fix most of it:**

1. **Is Docker actually running?** Installing it isn't enough. Start it and wait until it says
   *running*; that takes a minute or two after you log in.
2. **Are you in the right folder?** The one containing `start.command` / `start.bat` — the
   **inner** folder if you're on Windows.
3. **The first launch downloads about a gigabyte.** It can look frozen. It isn't. Once it
   finishes, every later launch takes seconds.

### Are you running an old copy?

If a lab behaves differently from its guide — a command it says to run comes back
`unknown command`, say — you are probably launching an out-of-date folder. Downloading the ZIP again
does **not** replace the old one: macOS and Windows keep both, as `assume-breach-labs-main 2`,
`assume-breach-labs-main 3`, and so on. It's easy to `cd` into the original by habit.

Check the line under the welcome banner:

```
  lab pack 2026.07.28
```

If that line is missing, or the date is older than the one on the unit site, delete the old folders,
[download the ZIP again](https://github.com/michael-borck/assume-breach-labs/archive/refs/heads/main.zip)
and launch from the fresh one. You don't need to clean up Docker — the launcher replaces stale lab
machines by itself.

Still stuck? Restart the computer. Genuinely — it fixes Docker more often than it should.

### Windows

| What you see | What it means |
|---|---|
| A window flashes open and disappears | Right-click inside the folder → **Open in Terminal**, type `.\start.bat`, press Enter. The message then stays on screen — usually "Docker Desktop isn't running". |
| *"Virtualization support not enabled"*, or a **WSL 2** error | See section 2, *"Windows only: turning on virtualisation"*. |
| *`bash` is not recognised* / double-clicking does nothing | Git for Windows isn't installed — it's the launcher. |
| *"Cannot connect to the Docker daemon"* | Docker Desktop isn't started, or hasn't finished starting. |
| Docker and VirtualBox fight | They compete for the same hardware. If you run VMs for another unit, close VirtualBox before starting a lab. |

### macOS

| What you see | What it means |
|---|---|
| *"cannot be opened because it is from an unidentified developer"* | macOS being careful. Right-click `start.command` → **Open** → **Open**. Once only. |
| *"Cannot connect to the Docker daemon"* | Docker Desktop isn't started. Open it from Applications and wait for *running*. |
| Double-clicking `start.sh` opens a text editor | Wrong file — use `start.command`. |

### Linux

| What you see | What it means |
|---|---|
| *"permission denied … /var/run/docker.sock"* | You're not in the `docker` group yet: `sudo usermod -aG docker $USER`, then **log out and back in**. |
| `docker: command not found` | Install **Docker Engine** plus the Compose plugin — not Docker Desktop. |
| `docker compose` unknown but `docker-compose` works | That's Compose v1. The labs need the v2 plugin. |

### Everything else

| Symptom | Fix |
|---|---|
| A container exits immediately | Check its logs: `docker logs <name>`. |
| Ports already in use | Another lab is still running — `quit` out of it, or `make stop`. |
| Build fails with `xattr … operation not permitted` | You're on an exFAT drive — prefix the command with `DOCKER_BUILDKIT=0`. |
| Downloads fail or time out | A VPN or restrictive network is blocking the image registry. Try without the VPN, or on campus. |
| Out of disk space | `docker system prune` reclaims space from old containers and images. |

**Anything else: bring it to the lab and we'll sort it out in the room.** You never lose lab work
to a broken laptop — the machines in 402.211 have Docker installed and ready to go.
