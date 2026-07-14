# Module 07 — Firewalls (Lab Guide)

**What this replaces:** the old Windows-only *iNetworkSimulator* firewall lab.
**What you actually use:** a real firewall (`iptables`) on real Linux machines — the same
technology that protects real networks, not a simulation.

You drive everything from a single **lab console**. You will *not* type any Docker commands: you
log in, and then use plain commands like `ping pc2 pc1` and `rules load`. The console shows you the
real command it runs on each machine (e.g. `[pc2] $ ping 10.1.1.2`) so you still learn the real
tools — see [Under the hood](#under-the-hood-the-real-commands) at the end.

## Lab Scenario

A small office network is split in two. The **inside** holds one protected workstation (`pc1`). The
**outside** holds three other staff machines (`pc2`, `pc3`, `pc4`). A **firewall** sits between them
and decides which traffic is allowed through. Your job: see how firewall rules — and the *order* you
write them in — control who can reach the protected machine, and understand the difference between
**dropping** traffic silently and **rejecting** it with a message.

```
        INSIDE  (protected)              OUTSIDE  (other staff)
     +------------------------+       +--------------------------+
     |  pc1   10.1.1.2        |  FW   |  pc2   10.1.2.3          |
     |  dns   10.1.1.253      | ----- |  pc3   10.1.2.4          |
     |                        |       |  pc4   10.1.2.5          |
     +------------------------+       +--------------------------+
        The firewall routes and filters traffic between the two sides.
```

## Getting in

From the repo folder, run:

```bash
./start.sh
```

(On Windows: install [Git for Windows](https://git-scm.com/download/win) once, then double-click `start.bat`.)

You'll see a welcome banner, the machines will power on, and you'll land at a `lab>` prompt. Type
`help` any time to see the commands. The ones you need:

| Command | What it does |
|---------|--------------|
| `ping <from> <to>` | Ping one machine from another, e.g. `ping pc2 pc1` |
| `rules show` | List the firewall's current rules |
| `rules load` | Apply this lab's teaching ruleset |
| `rules clear` | Remove all rules (allow everything) |
| `connect <host>` | Open a shell *on* a machine (for the curious) |
| `dns <name>` | Look up a name, e.g. `dns coke.dreamland.com.au` |
| `map` | Show the network diagram |
| `quit` | Leave the lab |

---

## Phase 1: The network with no firewall rules

The firewall starts **empty** — nothing is blocked. Establish that baseline.

```
lab> rules show
```

You should see an empty rule list. Now check that everyone can reach the protected machine:

```
lab> ping pc2 pc1
lab> ping pc3 pc1
lab> ping pc4 pc1
```

All three should succeed (`0% packet loss`).

> **Q1.** With no firewall rules, can every outside machine reach `pc1`? Paste the result of
> `ping pc2 pc1`.

> **Q2.** In one sentence each, what is **ICMP** and what is **`ping`**? (Hint: `ping` is the
> everyday tool; ICMP is the underlying message type it uses.)

---

## Phase 2: Apply firewall rules — DROP vs DENY

Now switch the firewall on with this lab's ruleset:

```
lab> rules load
lab> rules show
```

You'll see three rules, in order:

| # | Traffic | Action | Plain meaning |
|---|---------|--------|---------------|
| 1 | `pc2` → `pc1` (ping) | **DROP** | Silently throw it away |
| 2 | `pc3` → `pc1` (ping) | **REJECT** | Refuse it and send back an error |
| 3 | everything else | **ACCEPT** | Allow it |

Rules are read top to bottom, and the **first** matching rule wins.

> **Q3.** Before testing, predict: what's the difference between **DROP** (silent) and **REJECT**
> (refuse with an error), from the point of view of the person being blocked?

Now test each machine and watch *how* each one fails:

```
lab> ping pc2 pc1     # DROP   -> just hangs, then 100% loss, NO error
lab> ping pc3 pc1     # REJECT -> fails fast: "Destination Host Unreachable"
lab> ping pc4 pc1     # ACCEPT -> succeeds
```

> **Q4.** Record all three results. Which machine was *told* it was blocked, and which was met with
> silence? Why might a real firewall administrator prefer **DROP** (silence) at the edge of a
> network — what does silence deny an attacker?

Check how many packets each rule caught:

```
lab> rules show
```

> **Q5.** The `pkts` column counts packets that hit each rule. Which rule caught `pc2`'s traffic?
> Which caught `pc4`'s?

---

## Phase 3: Order matters

Firewalls read rules top to bottom and stop at the first match. This means the *order* of rules can
change everything. Let's prove it by putting an "allow" for `pc3` **above** the reject rule.

```
lab> connect firewall
```

You're now on the firewall itself (the prompt changes to `[firewall] $`). Insert an ACCEPT for
`pc3` at position 2, then look at the list:

```
[firewall] $ iptables -I FORWARD 2 -p icmp -s 10.1.2.4 -d 10.1.1.2 -j ACCEPT
[firewall] $ iptables -L FORWARD -n -v --line-numbers
[firewall] $ exit
```

Back at the `lab>` prompt, re-test `pc3`:

```
lab> ping pc3 pc1     # now SUCCEEDS — the new ACCEPT is reached before the REJECT
```

> **Q6.** `pc3` was blocked a moment ago and now gets through — and you never touched the reject
> rule. What changed? In one sentence, why does rule order matter when writing firewall policy?

Reset to the taught ruleset when you're done:

```
lab> rules load
```

---

## Phase 4: Reaching a machine by name (DNS)

Machines are easier to reach by name than by number. The lab has a name server. From the console:

```
lab> dns coke.dreamland.com.au
```

It resolves to `10.1.2.5` — that's `pc4`. So a name lookup plus the firewall's ACCEPT rule together
let you reach it.

> **Q7.** What address did `coke.dreamland.com.au` resolve to? Two separate things had to work for
> that to be useful — name resolution, and then the firewall allowing the traffic. Explain both in a
> sentence.

---

## Phase 5: Subnetting (a thinking exercise, no commands needed)

Two machines can talk directly only if they're on the **same subnet**. The subnet is decided by the
network mask.

- `pc2` is `10.1.2.3` and `pc4` is `10.1.2.5`, both with mask `/24` (`255.255.255.0`). The `/24`
  means the first three numbers (`10.1.2`) are the *network*; only the last number identifies the
  machine. Same network → they're on the same subnet.

> **Q8.** Consider `10.1.2.5` and `10.1.2.130`.
> (a) Under a `/24` mask, are they on the same subnet? (b) Under a `/25` mask (which splits
> `10.1.2.0` into `.0–.127` and `.128–.255`), are they still on the same subnet? Explain each answer.

---

## Wrapping up

Type `quit` to leave. You'll be asked whether to shut the machines down — say yes unless you're
coming straight back.

### Passport prompts (submit these)

Collect **Q1–Q8** into your lab journal, with:

- The three ping results from Phase 2 (DROP vs REJECT vs ACCEPT) side by side.
- A copy of `rules show` after Phase 3 (with the reordered rules).
- Your one-line definitions of **ICMP**, **DROP**, and **REJECT**.

---

## Under the hood: the real commands

You never had to type Docker, but everything above ran real tools on real machines. Here's what each
console command actually did, so you can do it yourself on any Linux system:

| Console command | Real command it ran |
|-----------------|---------------------|
| `ping pc2 pc1` | `ping 10.1.1.2` **on** the pc2 machine |
| `rules load` | `iptables` rules applied on the firewall (see `modules/module-07-firewalls/rules/rules.sh`) |
| `rules show` | `iptables -L FORWARD -n -v --line-numbers` on the firewall |
| `rules clear` | `iptables -F FORWARD` on the firewall |
| `connect pc3` | opened a shell on the pc3 machine |
| `dns coke.dreamland.com.au` | `getent hosts coke.dreamland.com.au` on pc1 |

The firewall ruleset (`rules.sh`) in full:

```sh
iptables -A FORWARD -p icmp -s 10.1.2.3 -d 10.1.1.2 -j DROP                                        # pc2 -> pc1: Drop
iptables -A FORWARD -p icmp -s 10.1.2.4 -d 10.1.1.2 -j REJECT --reject-with icmp-host-unreachable  # pc3 -> pc1: Deny
iptables -A FORWARD -j ACCEPT                                                                       # everything else: Permit
```
