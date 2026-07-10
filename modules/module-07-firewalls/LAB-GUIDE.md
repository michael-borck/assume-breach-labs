# Module 07 — Firewalls (Lab Guide)

**Replaces:** the Windows-only *iNetworkSimulator* firewall lab.
**You will use:** real `iptables` on real (containerised) Linux hosts — the same tool used in
production, not a simulator.

## Lab Scenario

A small network is split into an **inside** segment (one protected workstation) and an **outside**
segment (three other workstations). A **firewall** sits between them and routes traffic. Your job is
to see how firewall rules decide which traffic reaches the protected host, and — crucially — how the
**order** of rules and the **choice between DROP and REJECT** change what a user experiences.

```
        inside 10.1.1.0/24                     outside 10.1.2.0/24
     +-----------------------+             +--------------------------+
     |  pc1   10.1.1.2       |             |  pc2   10.1.2.3          |
     |  dns   10.1.1.253     |   FIREWALL  |  pc3   10.1.2.4          |
     |                       |  .254 | .254|  pc4   10.1.2.5          |
     +-----------------------+-------------+--------------------------+
                       routes + filters ICMP between the two nets
```

## Pre-Lab Setup

From the repo root:

```bash
make m07            # builds the tiny node image (first run) and starts 6 containers
docker ps           # confirm: m07-firewall, m07-pc1..pc4, m07-dns
```

Open a few terminals — one per host you're working on. To enter a host:

```bash
docker exec -it m07-pc1 sh        # the workstation on the inside
docker exec -it m07-firewall sh   # the firewall
```

Everything below is offline; no internet is used.

---

## Phase 1: The network before any firewall rules

The firewall starts with **no filter rules** — everything is permitted. Establish that baseline.

### 1.1 Look around

On **pc1** (`docker exec -it m07-pc1 sh`):

```sh
ip -4 -brief addr show      # pc1 is 10.1.1.2 on the inside net
ip route                    # note the route to 10.1.2.0/24 via the firewall (10.1.1.254)
```

### 1.2 Prove connectivity works

From **pc2** (`docker exec -it m07-pc2 sh`), ping the protected host:

```sh
ping -c 3 10.1.1.2          # succeeds — no rules yet
```

Repeat from **pc3** and **pc4** — all three should reach pc1.

> **Q1.** With no firewall rules, can every outside host reach pc1? Record the ping result from pc2.

### 1.3 Watch the traffic cross the firewall (ICMP + ARP)

On the **firewall**, watch packets as they are forwarded:

```sh
tcpdump -ni any icmp        # leave running
```

Now ping again from pc2. You'll see the echo request arrive on one interface and leave on the other
— the firewall is **routing** between the two networks. Stop with `Ctrl-C`.

> **Q2.** In one sentence each, define **ICMP** and **ARP**. (Hint: which one did `ping` use, and
> which one maps an IP to a hardware address on the same segment? Try `ip neigh` on pc2.)

---

## Phase 2: Apply a firewall ruleset (DROP vs DENY)

Now add rules on the firewall and watch behaviour change. This is the heart of the lab.

### 2.1 Load the ruleset

On the **firewall**:

```sh
/rules/rules.sh
```

This installs three ordered rules in the `FORWARD` chain:

| # | Match | Action | Original worksheet term |
|---|-------|--------|-------------------------|
| 0 | ICMP pc2 (10.1.2.3) → pc1 | `DROP` | Drop |
| 1 | ICMP pc3 (10.1.2.4) → pc1 | `REJECT --reject-with icmp-host-unreachable` | Deny |
| 2 | anything else | `ACCEPT` | Permit (catch-all) |

View them:

```sh
iptables -L FORWARD -n -v --line-numbers
```

> **Q3.** Explain the difference between **DROP** and **REJECT (Deny)** in your own words, *before*
> you test them.

### 2.2 Test each path and compare the experience

Run each ping and watch the **difference in how it fails**:

```sh
# From pc2  — matched by Rule 0 (DROP)
docker exec -it m07-pc2 ping -c 3 10.1.1.2      # times out: 100% loss, NO error message

# From pc3  — matched by Rule 1 (REJECT/Deny)
docker exec -it m07-pc3 ping -c 3 10.1.1.2      # fails fast: "Destination Host Unreachable"

# From pc4  — falls through to Rule 2 (ACCEPT)
docker exec -it m07-pc4 ping -c 3 10.1.1.2      # succeeds
```

> **Q4.** Record the exact output of all three. Which one told the sender it was blocked, and which
> one stayed silent? Why might a real firewall administrator prefer DROP (silence) at the network
> edge?

### 2.3 Watch the rule counters

On the firewall, re-run:

```sh
iptables -L FORWARD -n -v --line-numbers
```

> **Q5.** The `pkts`/`bytes` columns show how many packets hit each rule. Which rule caught pc2's
> traffic? Which caught pc4's?

---

## Phase 3: Rule ORDER matters

Firewalls evaluate rules top-to-bottom and stop at the first match. Prove it.

### 3.1 Move the catch-all above the Deny rule

On the **firewall**, insert an ACCEPT for pc3 *before* the REJECT (simulating "swap Rule 1 and Rule
2"):

```sh
iptables -I FORWARD 2 -p icmp -s 10.1.2.4 -d 10.1.1.2 -j ACCEPT
iptables -L FORWARD -n -v --line-numbers
```

### 3.2 Re-test pc3

```sh
docker exec -it m07-pc3 ping -c 3 10.1.1.2      # now SUCCEEDS — the ACCEPT is hit first
```

> **Q6.** pc3 was denied a moment ago and now succeeds, with no change to the Deny rule itself. What
> changed, and what does this tell you about writing firewall policy? Take a screenshot of the rule
> list showing the new order.

Reset to the taught ruleset when done: `/rules/rules.sh`.

---

## Phase 4: DNS through the firewall (optional but recommended)

The lab includes a DNS server (`dnsmasq`) on the inside net at `10.1.1.253`, serving the zone
`dreamland.com.au`.

On **pc1** (already pointed at the lab DNS):

```sh
getent hosts coke.dreamland.com.au    # resolves to 10.1.2.5 (pc4, on the outside net)
ping -c 3 coke.dreamland.com.au       # resolves by name AND routes through the firewall
```

> **Q7.** What IP did `coke.dreamland.com.au` resolve to? Explain the two separate things that had
> to work for the ping to succeed (name resolution, then forwarding).

---

## Phase 5: Subnetting (concept exercise)

This shows why two hosts with the *same* addresses can reach each other under one netmask but not
another — the concept the simulator taught by changing masks.

On **pc4**, temporarily give yourself a second address and reason about it:

```sh
ip addr show                          # note pc4 is 10.1.2.5/24
# 10.1.2.5 and 10.1.2.3 (pc2) share the 10.1.2.0/24 network -> same subnet.
# If pc4 were 10.1.2.5/26 and pc2 10.1.2.3/26, are they still in the same subnet? Work it out.
```

> **Q8.** For the pair `10.1.2.5` and `10.1.2.70`: are they in the same subnet under `/24`? Under
> `/26`? Show the network portion in each case and explain why a ping would or wouldn't work.

---

## Passport prompts (submit these)

Collect **Q1–Q8** above into your lab journal, with:

- The three ping outputs from Phase 2.2 (DROP vs REJECT vs ACCEPT) side by side.
- A screenshot of `iptables -L FORWARD -n -v --line-numbers` after Phase 3 (reordered rules).
- Your one-line definitions of ICMP, ARP, DROP, and REJECT.

## Lab Cleanup

```bash
make stop      # stop the containers
# or
make down      # stop and remove containers + networks
```

## Instructor notes

- **DROP vs REJECT** is the key takeaway and maps exactly onto the original "Drop vs Deny".
- **DHCP** (an exercise in the original simulator) is intentionally *not* reproduced live: Docker's
  own IP address management owns addressing on these networks, so a second DHCP server would fight
  it. The concept is covered by the static addressing students can already see with `ip addr`. If
  you want a live DHCP demo, run it on a separate throwaway network with Docker IPAM disabled — out
  of scope for this guide.
- All addressing matches `docker-compose.yml`; change it in one place if you re-address.
