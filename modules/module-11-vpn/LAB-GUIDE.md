# Module 11 — VPN & Tunnelling (Lab Guide)

**What this replaces:** nothing — the original unit taught VPNs only in slides. This is a new,
hands-on lab.
**What you actually use:** a real **WireGuard** VPN tunnel between two machines, with an eavesdropper
watching the network in between.

You saw in Module 06 that anything sent in the clear can be read off the wire. This lab shows the fix:
a VPN wraps your traffic in an encrypted tunnel, so the untrusted networks it crosses can't read it.

## Lab Scenario

A **client** in an office talks to a **server** in a datacentre. Between them sits an
**eavesdropper** — the untrusted infrastructure your traffic crosses in the real world (your ISP,
public Wi-Fi, the internet itself). Every packet between client and server passes through it. Your job
is to see what that eavesdropper can read, first without a VPN and then with one.

```
     client 10.11.0.10  ──►  EAVESDROPPER  ──►  server 10.11.1.20
       (office)               (on the path)       (login service :8080)
```

## Getting in

```bash
./start.sh
```

Pick module `11`. At the `lab>` prompt (`help` for the list):

| Command | What it does |
|---------|--------------|
| `eavesdrop` | the client logs in while the eavesdropper sniffs the wire |
| `vpn on` / `vpn off` | bring the WireGuard tunnel up / down |
| `status` | show whether the tunnel is up |
| `connect <host>` | shell on client / server / eavesdropper |

---

## Phase 1: Without a VPN — the wire is readable

The client logs into the server by sending its username and password. Watch what the eavesdropper
sees:

```
lab> eavesdrop
```

> **Q1.** What did the eavesdropper capture? Write down the exact line. Who, in the real world, is in
> a position to see this — name two places your traffic crosses that you don't control.

> **Q2.** The login used a normal web request (HTTP). Which module earlier showed you this same
> problem with a captured password, and what do these two labs together tell you about sending
> anything sensitive in the clear?

---

## Phase 2: Turn on the VPN

Bring up the encrypted tunnel between the client and the server:

```
lab> vpn on
lab> status
```

`status` shows the live WireGuard tunnel — a handshake, and an encrypted link between `10.99.0.2`
(client) and `10.99.0.1` (server).

> **Q3.** The tunnel gives each machine a new address on a private `10.99.0.0/24` network that only
> exists inside the encryption. In plain terms, what is a VPN doing here — what does "tunnel" mean?

---

## Phase 3: With the VPN — the wire goes dark

Now the client sends the very same login, but through the tunnel. Watch the eavesdropper again:

```
lab> eavesdrop
```

> **Q4.** Can the eavesdropper read the password now? What *does* it see instead? (Look at the
> protocol and port it reports.)

> **Q5.** The eavesdropper is still on the path and still sees traffic — the packets didn't disappear.
> So what exactly did the VPN change? Why can't the eavesdropper read the contents even though it
> receives every packet?

> **Q6.** A VPN protects data **in transit** across the untrusted network. Name one thing a VPN does
> **not** protect you from (think about the server at the far end, or malware on the client itself).

---

## Phase 4: Off again (optional)

```
lab> vpn off
lab> eavesdrop
```

Confirm the password is readable again the moment the tunnel is down — the protection only lasts as
long as the tunnel is up.

> **Q7.** Based on this lab, when should you insist on a VPN (or HTTPS/SSH, which tunnel individual
> connections the same way)? Give one everyday situation from your own life.

---

## Wrapping up

Type `quit` to leave (say `y` to shut the machines down).

### Passport prompts (submit these)

Collect **Q1–Q7** into your lab journal, with:

- The captured password from Phase 1 and a note of where in the real world it could be read.
- What the eavesdropper saw *with* the VPN on (protocol + port).
- One sentence explaining what a VPN protects and one thing it does **not** protect.

---

## Under the hood

- The tunnel is real **WireGuard** — the same VPN used in production. `vpn on` runs `wg-quick up wg0`
  on the client and server; `status` runs `wg show`.
- Without the VPN the client reaches the server directly (`10.11.1.20:8080`); with it up, it uses the
  tunnel address (`10.99.0.1`), so the packets on the wire are encrypted WireGuard UDP (port 51820).
- After `connect eavesdropper`, run `tcpdump -A -i any` yourself and watch the traffic live.
