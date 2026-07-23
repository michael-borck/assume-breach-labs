# Module 01 — Access Control & Isolation (Lab Guide)

**What this replaces:** the old "intro to virtualisation" lab where you set NTFS permissions on a
file in the Windows XP VM so user `rico` couldn't read it.
**What you actually use:** the same idea on real Linux — users, groups, file permissions, and ACLs —
which is what actually runs the servers you'll defend.

You are the **administrator** of an office server. You'll decide who can read a confidential file, and
learn the difference between "make it work" and "make it safe."

## Lab Scenario

The `/office` fileshare has a confidential `salaries.csv` and a public `notice.txt`. Three staff have
accounts: **rico**, **jane** (who works in HR), and **carlos**. Your job: make sure the right people —
and *only* the right people — can read the salary file. The theme is **least privilege**: grant the
minimum access needed, never more.

## Getting in

```bash
./start.sh
```

Pick module `01`. The workstation powers on and **logs you straight in as root** on the office
server — a real Linux shell, in `/office`. Type **`labhelp`** any time for the mission and the
commands you'll need.

Everything below is a real Linux command. Run them, inspect the output, and — because these are the
genuine tools, not lab shortcuts — feel free to ask an AI assistant to explain anything you don't
recognise. (The one command worth knowing up front: **`sudo -u rico cat salaries.csv`** tries to open
a file *as* that user, which is how you check whether your permissions actually work — the Linux
equivalent of "log out and log back in as rico.")

---

## Phase 1: Reading permissions

```bash
ls -l /office
```

Look at `salaries.csv`. Its permission string is `-rw-------` (mode **600**).

> **Q1.** The string `-rw-------` has three groups of three after the first character. What do the
> three groups mean (owner / group / others), and what do `r`, `w`, `x` stand for? Given mode 600, who
> can read `salaries.csv` right now?

Check your answer by trying to read it as rico:

```bash
sudo -u rico cat salaries.csv
```

> **Q2.** What happened, and why? (rico is not the owner, and "others" have no permissions.)

---

## Phase 2: The tempting wrong fix

jane needs to read the salary file for HR. The quickest fix is to make it readable by everyone:

```bash
chmod 644 salaries.csv
sudo -u rico cat salaries.csv
```

> **Q3.** After `chmod 644`, can **rico** read the confidential file now? Was rico supposed to? Explain
> why "just make it readable" is a security mistake — who else can now see the salaries?

This is the single most common access-control error: over-granting to solve an access problem. Undo
the damage in the next phase.

---

## Phase 3: The right fix — a group

Give access to a *group* of the right people, not to everyone. Put the file in an `hr` group and let
only that group read it:

```bash
chown root:hr salaries.csv
chmod 640 salaries.csv
```

Now `640` means: owner can read/write, **the hr group can read**, others get nothing. Add jane to hr,
then test both jane and rico:

```bash
usermod -aG hr jane
sudo -u jane cat salaries.csv
sudo -u rico cat salaries.csv
```

> **Q4.** Can jane read the file now? Can rico? Explain how jane got access **without** the file being
> readable by everyone. This is **least privilege** — access limited to exactly who needs it.
>
> *(If jane's read is denied on the very first try: group membership only applies at her next login.
> Re-running `sudo -u jane cat salaries.csv` starts a fresh session, which is why it then works.)*

---

## Phase 4: One person, without a group (ACLs)

Sometimes you need to grant just **one** extra person, and making a whole group is overkill. A
**POSIX ACL** grants a single user directly:

```bash
setfacl -m u:carlos:r salaries.csv
sudo -u carlos cat salaries.csv
getfacl salaries.csv
```

> **Q5.** carlos can now read the file even though he's not in the hr group. In the `getfacl` output,
> find the line that grants carlos access (`user:carlos:r--`). Also, `ls -l salaries.csv` now shows a
> `+` after the permissions — what does that `+` tell an administrator at a glance?

Remove it again when carlos no longer needs it:

```bash
setfacl -x u:carlos salaries.csv
sudo -u carlos cat salaries.csv
```

> **Q6.** Least privilege isn't only about granting the minimum — it's also about **removing** access
> when it's no longer needed. Why is stale access (accounts and permissions no one removed) a common
> way real breaches spread?

---

## Phase 5: Isolation (a thinking exercise)

You did all of this inside a container — an isolated Linux environment. The container is itself an
access-control boundary: what runs inside it can't see the rest of your computer.

> **Q7.** You have **two** layers of protection in play: the container isolates this whole system from
> your real machine, and *within* it, file permissions isolate users from each other. Give one real
> example of each kind of boundary in an organisation (one that separates whole systems, one that
> separates people within a system).

---

## Wrapping up

Type `exit` to leave (say `y` to shut the machine down). Your changes reset next time you start.

### Passport prompts (submit these)

Collect **Q1–Q7** into your lab journal, with:

- What `-rw-r-----` means, broken down into owner/group/other.
- The result of `sudo -u rico cat salaries.csv` before and after `chmod 644`, and why 644 was wrong.
- How you gave jane access the *right* way, and proof rico still couldn't read it.
- One sentence defining **least privilege** in your own words.

---

## Command reference

Every command in this lab is a standard Linux tool you'll use on real systems:

| Task | Command |
|------|---------|
| List files with permissions | `ls -l /office` |
| Show full permissions + ACLs | `getfacl salaries.csv` |
| Read a file **as** another user | `sudo -u jane cat salaries.csv` |
| Change permission bits | `chmod 640 salaries.csv` |
| Change owner / group | `chown root:hr salaries.csv` |
| Add a user to a group | `usermod -aG hr jane` |
| Check a user's groups | `id jane` |
| Grant one user access (ACL) | `setfacl -m u:carlos:r salaries.csv` |
| Remove that ACL | `setfacl -x u:carlos salaries.csv` |

You are root on `station`, working in `/office` — run these yourself, inspect the results, and don't
be afraid to break things. Everything resets when you restart the lab.
