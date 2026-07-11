# Module 02 — Port Scanning & Enumeration (Lab Guide)

**What this replaces:** the old lab that scanned live internet hosts (`scanme.nmap.org`,
`ecu.edu.au`) with Zenmap in the XP VM.
**What you actually use:** **nmap**, the industry-standard scanner, against a **safe internal lab
network** you're authorised to test — no scanning of the public internet.

You drive everything from the lab console; you won't type Docker. Each command shows the real nmap
command it runs (e.g. `[attacker] $ nmap -F 10.2.0.20`) so you learn the tool — see
[Under the hood](#under-the-hood-the-real-commands).

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

Pick module `02`. At the `lab>` prompt (`help` for the list):

| Command | What it does |
|---------|--------------|
| `discover` | Find which machines are alive on the network |
| `scan <host>` | Quick scan of a host's common ports |
| `ports <host>` | Fuller scan (top 1000 ports) |
| `version <host>` | Identify the service **and version** on each open port |
| `intense <host>` | Aggressive scan (version, OS guess, scripts) |
| `connect attacker` | Shell on the workstation to run nmap yourself |

---

## Phase 1: Who's out there? (host discovery)

Before scanning ports, find the live hosts:

```
lab> discover
```

This is a **ping sweep** — it asks every address on the network "are you there?" without checking any
ports.

> **Q1.** How many hosts are alive, and what are their IP addresses? (You'll see the three named
> machines plus your own attacker box and the network gateway.)

> **Q2.** In your own words: what is an **IP address**, and what is a **port**? (An analogy: if the
> IP address is a building's street address, what is a port?)

---

## Phase 2: What's running? (port scanning)

Pick a host and scan its common ports:

```
lab> scan web
lab> scan files
lab> scan app
```

> **Q3.** List the open ports on each of the three hosts. Which host is clearly a **web server**?
> Which looks like a **file server**?

Now scan more thoroughly — `scan` checks common ports quickly; `ports` checks the top 1000:

```
lab> ports app
```

> **Q4.** Did the fuller scan on `app` find any port the quick scan missed? Why might a quick scan
> miss a service running on an unusual port — and why would an attacker bother with the slower, fuller
> scan?

---

## Phase 3: What *exactly* is running? (version detection)

An open port tells you *something* is listening. **Version detection** tells you *what* — the
software and its version, which is what lets you look up known vulnerabilities.

```
lab> version files
lab> version app
```

> **Q5.** Record the service **and version** for each open port on `files` and `app` (e.g.
> `22/tcp OpenSSH 9.2`, `21/tcp vsftpd 3.0.3`). Why is knowing the *version* far more useful to both
> an attacker and a defender than just knowing "something is on port 22"?

### The mystery service

`version app` finds something on port **9000** that nmap can't fully identify. Investigate it
yourself — connect to the workstation and talk to the port directly:

```
lab> connect attacker
[attacker] $ nc 10.2.0.40 9000
[attacker] $ exit
```

> **Q6.** What did the service on port 9000 tell you about itself? What does this show about services
> that run on non-standard ports — can "hiding" on an unusual port keep a service secret?

---

## Phase 4: The aggressive scan

`intense` combines version detection, an OS guess, and default scripts in one noisy scan:

```
lab> intense files
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

Type `quit` to leave (say `y` to shut the machines down).

### Passport prompts (submit these)

Collect **Q1–Q8** into your lab journal, with:

- Your network map: the three hosts, their open ports, and the service+version on each.
- What the port-9000 mystery service turned out to be, and how you found out.
- Two sentences on the difference between a quick scan and an aggressive scan, and when you'd use
  each.

---

## Under the hood: the real commands

You never typed Docker; every scan was real nmap run from the attacker machine:

| Console command | Real command it ran |
|-----------------|---------------------|
| `discover` | `nmap -sn 10.2.0.0/24` (ping sweep, no port scan) |
| `scan web` | `nmap -F 10.2.0.20` (fast — top 100 ports) |
| `ports app` | `nmap 10.2.0.40` (top 1000 ports) |
| `version files` | `nmap -sV 10.2.0.30` (service + version detection) |
| `intense files` | `nmap -A -T4 10.2.0.30` (aggressive: -sV, OS, scripts, traceroute) |

Try them yourself after `connect attacker`. `nmap` has a manual at `man nmap` and the flags you'll
use most are `-p` (choose ports), `-sV` (versions), and `-T0..-T5` (speed/stealth).
