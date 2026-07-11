# Module 06 — Packet Capture & Analysis (Lab Guide)

**What this replaces:** the old lab's Wireshark-in-the-XP-VM with the `ex2/ex3/ex4.cap` files.
**What you actually use:** the **real Wireshark**, running in your web browser, analysing real capture
files.

This is a browser module: you log in, Wireshark opens in your browser, and you analyse capture files
that are already on the machine in `/pcaps`.

## Lab Scenario

A network tap recorded traffic on a small office LAN. Your job is to read those recordings the way an
investigator (or an attacker) would — pulling usernames and passwords straight out of unencrypted
traffic, reconstructing what happened in a session, and recognising a port scan. The defensive lesson
lands hard here: anything sent in the clear is readable by anyone on the path, which is *why* we
encrypt.

## Getting in

```bash
./start.sh
```

Pick module `06`. When it's up, type `open` (or go to **http://localhost:3006**) to open Wireshark in
your browser. The captures are in **`/pcaps`** — in Wireshark use **File ▸ Open** and type
`/pcaps/` to see them:

| File | What it holds |
|------|---------------|
| `ftp-login.pcap` | a cleartext FTP login |
| `telnet-login.pcap` | a telnet login — one failed attempt, then success |
| `http-browse.pcap` | a plain HTTP page fetch |
| `dns-query.pcap` | a DNS name lookup |
| `icmp-ping.pcap` | a ping (ICMP echo/reply) |
| `port-scan.pcap` | a TCP SYN port scan |

Console commands: `open` (launch Wireshark), `list` (list the captures), `fetch` (download extra
real-world samples), `connect wireshark` (a shell, for `tshark`).

---

## Phase 1: Credentials in the clear (FTP)

Open `/pcaps/ftp-login.pcap`. Scroll the packet list — the **Info** column narrates the conversation.

> **Q1.** Find the two packets that carry the login. What **username** and **password** were used?
> (Look for the `USER` and `PASS` commands.)

Right-click any packet in the conversation and choose **Follow ▸ TCP Stream** to see the whole
exchange as plain text.

> **Q2.** FTP sent that password across the network in readable text. Name the encrypted protocol you
> would use instead so the password *couldn't* be read this way.

---

## Phase 2: Reconstruct a session (telnet)

Open `/pcaps/telnet-login.pcap`, right-click a packet, and **Follow ▸ TCP Stream**.

> **Q3.** The user's first login attempt failed and the second succeeded. What password did they try
> first, what error did the server give, and what password finally worked?

> **Q4.** From the reconstructed stream alone, what command did the user run after logging in, and
> what was the reply? What does this show about what an eavesdropper on a telnet session can see?

---

## Phase 3: Web and name lookups

Open `/pcaps/http-browse.pcap`.

> **Q5.** What page did the browser request (the `GET` line), and what server software answered? Would
> an eavesdropper be able to read the page contents here? What changes with **HTTPS**?

Open `/pcaps/dns-query.pcap`.

> **Q6.** What hostname was looked up, and what IP address did the DNS server return for it? (This is
> the same DNS-resolution step your computer does before every web request.)

---

## Phase 4: Spot the scan

Open `/pcaps/port-scan.pcap`. This is one machine probing another's ports — the same activity you
performed in Module 02, now seen from the *defender's* side of the wire.

Apply the display filter `tcp.flags.syn == 1 && tcp.flags.ack == 0` (type it in the filter bar and
press Enter) to see just the probe packets.

> **Q7.** How many ports were probed? Now filter for the replies with `tcp.flags.syn == 1 &&
> tcp.flags.ack == 1` (a SYN/ACK means "open"). Which ports answered as **open**? What reply did the
> **closed** ports send instead (look for `RST`)?

> **Q8.** If you were watching this network live, what would tell you a scan was happening — one host
> sending many SYNs to many ports in a short time? How could a defender detect or block that?

---

## Phase 5 (optional): Real-world captures

The six files above are crafted for teaching. To practise on messier, real traffic, download a
curated set of external sample captures:

```
lab> fetch
```

New files appear in `/pcaps` (e.g. `sample-http.pcap`). Open them and explore — real captures are
noisier and are excellent practice.

> **Power users:** `fetch` just runs `fetch-samples` inside the container, which downloads the URLs
> listed in `/pcaps/.samples.txt`. Instructors can edit that list to add their own captures.

---

## Wrapping up

Close the browser tab and type `quit` in the console (say `y` to shut the machine down).

### Passport prompts (submit these)

Collect **Q1–Q8** into your lab journal, with:

- The FTP username and password you recovered, and the encrypted protocol you'd use instead.
- The telnet story: the failed password, the error, and the one that worked.
- The DNS lookup result (name → IP).
- The port-scan summary: how many ports probed, which were open, and how closed ports replied.
- Two sentences: why capturing traffic is so revealing, and what encryption changes about it.

---

## Under the hood

- Wireshark runs as a real Linux desktop application streamed to your browser (no VM, no install).
- The teaching captures are **crafted for this lab** and ship with it. Real-world captures are
  **downloaded on demand** (`fetch`) rather than redistributed, so the repo carries no third-party
  capture files.
- Everything you did in the GUI has a command-line twin: after `connect wireshark`, try
  `tshark -r /pcaps/ftp-login.pcap -Y ftp` to see the same FTP packets in the terminal.
