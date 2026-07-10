# Going Further — Extension Labs

Optional, more advanced labs for students who finish early or want to push past the core unit.
These live in **separate repositories** (they're heavier, and shared with other courses), but they
run the same way: `docker compose up -d` and a guide. Framed here for a defensive/first-course
audience — the point is to *understand attacks in order to defend against them*.

| Extension | What you do | Ties to core module | Repo |
|-----------|-------------|---------------------|------|
| **Web application vulnerabilities** | Find and exploit SQL injection and XSS in DVWA / OWASP Juice Shop, then read the fix | Cryptography (04), Human Factors (09) | `ethical-hacking-docker-labs` (week 7) |
| **Lateral movement & pivoting** | Use SSH/SOCKS tunnels to reach a host you can't touch directly, through a compromised jump box | Firewalls (07) — the attacker's view of your rules | `cybersecurity-lab-lateral-movement` |
| **Full pentest capstone (De-ICE S1.100)** | Recon → enumerate → crack → escalate on a deliberately vulnerable target, end to end | Port scanning (02) + Password attacks (03) combined | `ethical-hacking-docker-labs` (week 8) |
| **Digital forensics investigation** | Disk/memory analysis of a simulated data-exfiltration incident with Sleuth Kit, Volatility, YARA | Forensics (08), scaled up | `forensics-docker-lab` |

## How to use these

- They are **not assessed** here — treat them as enrichment.
- Each is self-contained with its own `README`/`LAB-GUIDE`. Clone the repo, follow its quick start.
- If you want any of these folded into this repo as a first-class `module-1X` extension (so they
  appear in `make status` and the single compose file), that's a deliberate next step — see the
  migration plan.

## A note on ethics

Everything here is designed to run against **targets you own** inside an isolated Docker network.
Scanning, cracking, or exploiting systems you do not have written permission to test is illegal in
most jurisdictions. The skills are defensive: you learn how an attacker works so you can close the
gaps first.
