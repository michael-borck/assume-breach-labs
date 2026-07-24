# Module 07 — Firewalls (Lab Guide)

**What this replaces:** the old Windows-only *iNetworkSimulator* firewall lab.
**What you actually use:** a real firewall (`iptables`) on real Linux machines — the same
technology that protects real networks, not a simulation.

You never type any Docker. You "log in" to the **firewall** — the machine you administer — and use
real `iptables` there. To test your rules, you `ssh` to a workstation and `ping` across the firewall,
exactly as a real network engineer would. These are the real commands, so an AI assistant can help
you read any output.

## Lab Scenario

A small office network is split in two. The **inside** holds one protected workstation (`pc1`). The
**outside** holds three other staff machines (`pc2`, `pc3`, `pc4`). A **firewall** sits between them
and decides which traffic is allowed through. Your job: see how firewall rules — and the *order* you
write them in — control who can reach the protected machine, and understand the difference between
**dropping** traffic silently and **rejecting** it with a message.

```
        INSIDE  (protected)                 OUTSIDE  (other staff)
     +----------------------+            +------------------------+
     |  pc1   10.1.1.2      |            |  pc2   10.1.2.3        |
     |  dns   10.1.1.253    | [FIREWALL] |  pc3   10.1.2.4        |
     |                      |  in .1.254 |  pc4   10.1.2.5        |
     +----------------------+  out .2.254+------------------------+
        The firewall routes and filters traffic between the two sides.
```

## Getting in

```bash
./start.sh
```

(On Windows: install [Git for Windows](https://git-scm.com/download/win) once, then double-click `start.bat`.)

Pick module `07`. The machines power on and you're **logged in as root on the firewall**. Type
**`labhelp`** for the commands and **`netmap`** to redraw the network any time.

Two places you'll work:
- **On the firewall** (where you start) — manage the rules with `iptables`.
- **On a workstation** — `ssh pc2` to hop there, run your test, then `exit` back to the firewall.

---

## Phase 1: The network with no firewall rules

The firewall starts **empty** — nothing is blocked. Establish that baseline. On the firewall:

```bash
iptables -L FORWARD -n -v --line-numbers
```

You should see an empty FORWARD rule list. Now check that the outside machines can reach the
protected machine — hop to each and ping `pc1`:

```bash
ssh pc2
ping -c3 pc1
exit
```

Repeat from `pc3` and `pc4` (`ssh pc3` … `ping -c3 pc1` … `exit`). All three should succeed
(`0% packet loss`).

> **Q1.** With no firewall rules, can every outside machine reach `pc1`? Paste the result of
> `ping -c3 pc1` run from `pc2`.

> **Q2.** In one sentence each, what is **ICMP** and what is **`ping`**? (Hint: `ping` is the
> everyday tool; ICMP is the underlying message type it uses.)

---

## Phase 2: Apply firewall rules — DROP vs REJECT

Back on the firewall, switch on this lab's ruleset and look at it:

```bash
/rules/rules.sh
iptables -L FORWARD -n -v --line-numbers
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

Now test each machine and watch *how* each one fails. From the firewall, `ssh` to each and ping:

```bash
ssh pc2      # then:  ping -c3 pc1   -> DROP:   just hangs, then 100% loss, NO error
ssh pc3      # then:  ping -c3 pc1   -> REJECT: fails fast, "Destination Host Unreachable"
ssh pc4      # then:  ping -c3 pc1   -> ACCEPT: succeeds
```

(Run `ping -c3 pc1` after each `ssh`, then `exit` back to the firewall.)

> **Q4.** Record all three results. Which machine was *told* it was blocked, and which was met with
> silence? Why might a real firewall administrator prefer **DROP** (silence) at the edge of a
> network — what does silence deny an attacker?

Check how many packets each rule caught — on the firewall:

```bash
iptables -L FORWARD -n -v --line-numbers
```

> **Q5.** The `pkts` column counts packets that hit each rule. Which rule caught `pc2`'s traffic?
> Which caught `pc4`'s?

---

## Phase 3: Order matters

Firewalls read rules top to bottom and stop at the first match, so the *order* of rules can change
everything. Prove it by inserting an ACCEPT for `pc3` **above** the reject rule. On the firewall:

```bash
iptables -I FORWARD 2 -p icmp -s 10.1.2.4 -d 10.1.1.2 -j ACCEPT
iptables -L FORWARD -n -v --line-numbers
```

Now re-test `pc3`:

```bash
ssh pc3
ping -c3 pc1     # now SUCCEEDS — the new ACCEPT is reached before the REJECT
exit
```

> **Q6.** `pc3` was blocked a moment ago and now gets through — and you never touched the reject
> rule. What changed? In one sentence, why does rule order matter when writing firewall policy?

Reset to the taught ruleset when you're done (on the firewall):

```bash
/rules/rules.sh
```

---

## Phase 4: Reaching a machine by name (DNS)

Machines are easier to reach by name than by number. The lab has a name server (`dns`, 10.1.1.253),
and `pc1` is configured to use it. Hop to `pc1` and look a name up:

```bash
ssh pc1
getent hosts coke.dreamland.com.au
exit
```

It resolves to `10.1.2.5` — that's `pc4`.

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

Type `exit` on the firewall to leave. You'll be asked whether to shut the machines down — say yes
unless you're coming straight back. Your changes reset next time you start.

### Passport prompts (submit these)

Collect **Q1–Q8** into your lab journal, with:

- The three ping results from Phase 2 (DROP vs REJECT vs ACCEPT) side by side.
- A copy of `iptables -L FORWARD -n -v --line-numbers` after Phase 3 (with the reordered rules).
- Your one-line definitions of **ICMP**, **DROP**, and **REJECT**.

---

## Command reference

Everything is real tools on real machines. On the **firewall** you manage the ruleset; from a
**workstation** (reached with `ssh`) you test it.

| Where | Task | Command |
|-------|------|---------|
| firewall | Show the FORWARD rules | `iptables -L FORWARD -n -v --line-numbers` |
| firewall | Load the teaching ruleset | `/rules/rules.sh` |
| firewall | Clear all rules (allow all) | `iptables -F FORWARD` |
| firewall | Insert a rule at position N | `iptables -I FORWARD 2 -p icmp -s 10.1.2.4 -d 10.1.1.2 -j ACCEPT` |
| firewall | Hop to a workstation | `ssh pc2` (then `exit` to return) |
| workstation | Ping across the firewall | `ping -c3 pc1` |
| pc1 | Look a name up (DNS) | `getent hosts coke.dreamland.com.au` |

The firewall ruleset (`rules/rules.sh`) in full:

```sh
iptables -A FORWARD -p icmp -s 10.1.2.3 -d 10.1.1.2 -j DROP                                        # pc2 -> pc1: Drop
iptables -A FORWARD -p icmp -s 10.1.2.4 -d 10.1.1.2 -j REJECT --reject-with icmp-host-unreachable  # pc3 -> pc1: Deny
iptables -A FORWARD -j ACCEPT                                                                       # everything else: Permit
```
