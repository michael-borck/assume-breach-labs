# Module 11 — VPN & Tunnelling (Lab Guide)

**What this replaces:** nothing — the original unit taught VPNs only in slides. This is a new,
hands-on lab.
**What you actually use:** a real **WireGuard** VPN tunnel between two machines, with an eavesdropper
watching the network in between.

You saw in Module 06 that anything sent in the clear can be read off the wire. This lab shows the fix:
a VPN wraps your traffic in an encrypted tunnel, so the untrusted networks it crosses can't read it.
You never type Docker — you log into the client and run the real tools (`curl`, `ssh`, `wg-quick`,
`tcpdump`), so an AI assistant can help you read any output.

## Lab Scenario

A **client** in an office talks to a **server** in a datacentre. Between them sits an
**eavesdropper** — the untrusted infrastructure your traffic crosses in the real world (your ISP,
public Wi-Fi, the internet itself). Every packet between client and server passes through it. Your job
is to see what that eavesdropper can read, first without a VPN and then with one.

```
     client 10.11.0.10  ──►  EAVESDROPPER  ──►  server 10.11.1.20
       (office, you)          (on the path)       (login service :8080)
```

## Getting in

```bash
./start.sh
```

Pick module `11`. The machines power on and you're **logged in as root on the client**. Type
**`labhelp`** for the commands and **`netmap`** to redraw the network any time. The eavesdropper is
already capturing the wire to `/var/log/wire.log` — you'll read it with `ssh`.

---

## Phase 1: Without a VPN — the wire is readable

From the client, log into the server by sending a username and password (a normal cleartext HTTP
request):

```bash
curl -s http://server:8080/login -d 'user=admin&password=Sup3rSecret!'
```

Now read what the eavesdropper caught off the wire:

```bash
ssh eavesdropper 'grep -a "password=" /var/log/wire.log'
```

> **Q1.** What did the eavesdropper capture? Write down the exact line. Who, in the real world, is in
> a position to see this — name two places your traffic crosses that you don't control.

> **Q2.** The login used a normal web request (HTTP). Which module earlier showed you this same
> problem with a captured password, and what do these two labs together tell you about sending
> anything sensitive in the clear?

---

## Phase 2: Turn on the VPN

Bring up the encrypted WireGuard tunnel — it needs both ends. On the client, then the server:

```bash
wg-quick up wg0
ssh server 'wg-quick up wg0'
wg show
```

`wg show` displays the live tunnel — a handshake, and an encrypted link between `10.99.0.2` (client)
and `10.99.0.1` (server).

> **Q3.** The tunnel gives each machine a new address on a private `10.99.0.0/24` network that only
> exists inside the encryption. In plain terms, what is a VPN doing here — what does "tunnel" mean?

---

## Phase 3: With the VPN — the wire goes dark

Send the very same login, but this time to the server's **tunnel address** (`10.99.0.1`), so it
travels inside the encrypted tunnel. First clear the eavesdropper's old capture so the comparison is
clean, then send and re-read the wire:

```bash
ssh eavesdropper ': > /var/log/wire.log'
curl -s http://10.99.0.1:8080/login -d 'user=admin&password=Sup3rSecret!'
ssh eavesdropper 'grep -a "password=" /var/log/wire.log'      # -> nothing this time
ssh eavesdropper 'grep -c 51820 /var/log/wire.log'            # -> encrypted WireGuard packets
```

> **Q4.** Can the eavesdropper read the password now? What *does* it see instead? (Look at the
> protocol and port — UDP 51820 is WireGuard.)

> **Q5.** The eavesdropper is still on the path and still sees traffic — the packets didn't disappear.
> So what exactly did the VPN change? Why can't the eavesdropper read the contents even though it
> receives every packet?

> **Q6.** A VPN protects data **in transit** across the untrusted network. Name one thing a VPN does
> **not** protect you from (think about the server at the far end, or malware on the client itself).

---

## Phase 4: Off again (optional)

```bash
wg-quick down wg0
ssh server 'wg-quick down wg0'
ssh eavesdropper ': > /var/log/wire.log'
curl -s http://server:8080/login -d 'user=admin&password=Sup3rSecret!'
ssh eavesdropper 'grep -a "password=" /var/log/wire.log'
```

Confirm the password is readable again the moment the tunnel is down — the protection only lasts as
long as the tunnel is up.

> **Q7.** Based on this lab, when should you insist on a VPN (or HTTPS/SSH, which tunnel individual
> connections the same way)? Give one everyday situation from your own life.

---

## Wrapping up

Type `exit` on the client to leave (say `y` to shut the machines down). Your changes reset next time.

### Passport prompts (submit these)

Collect **Q1–Q7** into your lab journal, with:

- The captured password from Phase 1 and a note of where in the real world it could be read.
- What the eavesdropper saw *with* the VPN on (protocol + port).
- One sentence explaining what a VPN protects and one thing it does **not** protect.

---

## Command reference

Everything is real tools on real machines. You work from the **client** and `ssh` to the others.

| Where | Task | Command |
|-------|------|---------|
| client | Send a login in the clear | `curl -s http://server:8080/login -d 'user=admin&password=Sup3rSecret!'` |
| client | Read what the wire caught | `ssh eavesdropper 'grep -a "password=" /var/log/wire.log'` |
| client | Bring the tunnel up (this end) | `wg-quick up wg0` |
| client | Bring the tunnel up (server end) | `ssh server 'wg-quick up wg0'` |
| client | Show the tunnel state | `wg show` |
| client | Send a login through the tunnel | `curl -s http://10.99.0.1:8080/login -d 'user=admin&password=Sup3rSecret!'` |
| client | Clear the eavesdropper's capture | `ssh eavesdropper ': > /var/log/wire.log'` |
| client | Tear the tunnel down | `wg-quick down wg0` (and `ssh server 'wg-quick down wg0'`) |

- The tunnel is real **WireGuard** — the same VPN used in production. The client and server configs
  (`/etc/wireguard/wg0.conf`) are provided; you bring the tunnel up with `wg-quick`.
- Without the VPN the client reaches the server directly (`server:8080` = `10.11.1.20`); with it up,
  it uses the tunnel address (`10.99.0.1`), so the packets on the wire are encrypted WireGuard UDP
  (port 51820).
- On the eavesdropper you can also watch live: `ssh eavesdropper` then `tcpdump -A -nn -i any`.
