# Module 02 — Port Scanning & Enumeration (Lab Guide)

**What this replaces:** the old lab that scanned live internet hosts (`scanme.nmap.org`,
`ecu.edu.au`) with Zenmap in the XP VM.
**What you actually use:** **nmap**, the industry-standard scanner, against a **safe internal lab
network** you're authorised to test — no scanning of the public internet.

You never type Docker. You "log in" to a real attacker workstation and run **real nmap** against a
real network — the commands you run here are the commands you'd run on a real engagement.

## Lab Scenario

You've been given authorised access to a small network — `10.2.0.0/24` — and asked to map it: which
machines are alive, what services they run, and which of those services are old or unexpected.
Scanning is the reconnaissance step of any assessment. The lesson is two-sided: it's how a defender
audits their own exposure, and it's the first thing an attacker does — which is why doing it to
systems you don't own is a crime (Phase 5).

```
     attacker 10.2.0.10   ── network 10.2.0.0/24 ──┐
       (you, with nmap)                            │
                        web    10.2.0.20   ? ports
                        files  10.2.0.30   ? ports
                        app    10.2.0.40   ? ports
```

You don't know the ports yet. Finding them is the job.

## Getting in

```bash
./start.sh
```

Pick module `02`. The workstation powers on and **logs you straight in as root** on the attacker
box (`10.2.0.10`) — a real shell with `nmap`. Type **`labhelp`** any time for the scanning commands
and the target list.

Because these are the genuine tools, feel free to ask an AI assistant to explain any flag or any line
of output you don't recognise.

---

## Phase 1: Who's out there? (host discovery)

Before scanning ports, find the live hosts with a ping sweep — it asks every address on the network
"are you there?" without checking any ports:

```bash
nmap -sn 10.2.0.0/24
```

> **Q1.** How many hosts are alive, and what are their IP addresses? (You'll see the three named
> machines plus your own attacker box and the network gateway.)

> **Q2.** In your own words: what is an **IP address**, and what is a **port**? (An analogy: if the
> IP address is a building's street address, what is a port?)

---

## Phase 2: What's running? (port scanning)

Pick a host and scan its common ports. `-F` is a **fast** scan (top 100 ports):

```bash
nmap -F 10.2.0.20      # web
nmap -F 10.2.0.30      # files
nmap -F 10.2.0.40      # app
```

> **Q3.** List the open ports on each of the three hosts. Which host is clearly a **web server**?
> Which looks like a **file server**?

Now scan more thoroughly. Without `-F`, nmap checks the top **1000** ports:

```bash
nmap 10.2.0.40         # app — fuller scan
```

> **Q4.** Did the fuller scan on `app` find any port the fast scan missed? Why might a fast scan miss
> a service running on an unusual port — and why would an attacker bother with the slower, fuller
> scan?

---

## Phase 3: What *exactly* is running? (version detection)

An open port tells you *something* is listening. **Version detection** (`-sV`) tells you *what* — the
software and its version, which is what lets you look up known vulnerabilities:

```bash
nmap -sV 10.2.0.30     # files
nmap -sV 10.2.0.40     # app
```

> **Q5.** Record the service **and version** for each open port on `files` and `app` (e.g.
> `22/tcp OpenSSH 9.2`, `21/tcp vsftpd 3.0.3`). Why is knowing the *version* far more useful to both
> an attacker and a defender than just knowing "something is on port 22"?

### The mystery service

`nmap -sV 10.2.0.40` finds something on port **9000** that nmap can't fully identify. Investigate it
yourself — talk to the port directly with netcat:

```bash
nc 10.2.0.40 9000
# read what it says, then press Ctrl-C to stop
```

> **Q6.** What did the service on port 9000 tell you about itself? What does this show about services
> that run on non-standard ports — can "hiding" on an unusual port keep a service secret?

---

## Phase 4: The aggressive scan

`-A` combines version detection, an OS guess, and default scripts in one noisy scan (`-T4` speeds it
up):

```bash
nmap -A -T4 10.2.0.30  # files
```

> **Q7.** The aggressive scan is far more informative — and far **louder** (it sends many more
> packets and is easily logged). When would a penetration tester choose a quiet scan over this one?

---

## Phase 5: The law (a written exercise)

Everything you just did against this lab network would be a **criminal offence** if done to a system
you don't own or have written permission to test. In Australia this falls under the *Criminal Code
Act 1995* (unauthorised access/impairment of computers); most countries have equivalent laws (e.g.
the US *Computer Fraud and Abuse Act*, the UK *Computer Misuse Act*).

> **Q8.** Why is port scanning someone else's system treated as an offence, even though you didn't
> break in or change anything? (Think about what reconnaissance is a precursor to, and why the law
> acts early.)

---

## Wrapping up

Type `exit` to leave (say `y` to shut the machines down). Your changes reset next time you start.

### Passport prompts (submit these)

Collect **Q1–Q8** into your lab journal, with:

- Your network map: the three hosts, their open ports, and the service+version on each.
- What the port-9000 mystery service turned out to be, and how you found out.
- Two sentences on the difference between a fast scan and an aggressive scan, and when you'd use each.

---

## Command reference

Every scan is real nmap, run from the attacker workstation:

| Task | Command |
|------|---------|
| Host discovery (ping sweep) | `nmap -sn 10.2.0.0/24` |
| Fast scan (top 100 ports) | `nmap -F 10.2.0.20` |
| Fuller scan (top 1000 ports) | `nmap 10.2.0.40` |
| Service + version detection | `nmap -sV 10.2.0.30` |
| Aggressive (version, OS, scripts) | `nmap -A -T4 10.2.0.30` |
| Talk to a service directly | `nc 10.2.0.40 9000` |
| Scan specific ports | `nmap -p 22,80,8080 10.2.0.30` |

Targets: **web** `10.2.0.20`, **files** `10.2.0.30`, **app** `10.2.0.40`. `nmap` has a full manual
at `man nmap`; the flags you'll use most are `-p` (choose ports), `-sV` (versions), and `-T0..-T5`
(speed/stealth).
