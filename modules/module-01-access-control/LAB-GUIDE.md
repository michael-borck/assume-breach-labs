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

Pick module `01`. At the `lab>` prompt (`help` for the list). The key command is **`read <user>
<file>`** — it tries to open a file *as that user*, which is how you check whether your permissions
actually work (the Linux version of "log out and log back in as rico").

| Command | What it does |
|---------|--------------|
| `files` | list the office files and their permissions |
| `read <user> <file>` | try to read a file **as** that user |
| `perms <file>` | full permissions + any ACLs |
| `chmod <mode> <file>` | change permissions |
| `chown <owner[:group]> <file>` | change owner/group |
| `addgroup <user> <group>` | add a user to a group |
| `grant <user> <file>` / `revoke <user> <file>` | give/remove one user's access (ACL) |

---

## Phase 1: Reading permissions

```
lab> files
```

Look at `salaries.csv`. Its permission string is `-rw-------` (mode **600**).

> **Q1.** The string `-rw-------` has three groups of three after the first character. What do the
> three groups mean (owner / group / others), and what do `r`, `w`, `x` stand for? Given mode 600, who
> can read `salaries.csv` right now?

Check your answer by trying to read it as rico:

```
lab> read rico salaries.csv
```

> **Q2.** What happened, and why? (rico is not the owner, and "others" have no permissions.)

---

## Phase 2: The tempting wrong fix

jane needs to read the salary file for HR. The quickest fix is to make it readable by everyone:

```
lab> chmod 644 salaries.csv
lab> read rico salaries.csv
```

> **Q3.** After `chmod 644`, can **rico** read the confidential file now? Was rico supposed to? Explain
> why "just make it readable" is a security mistake — who else can now see the salaries?

This is the single most common access-control error: over-granting to solve an access problem. Undo
the damage in the next phase.

---

## Phase 3: The right fix — a group

Give access to a *group* of the right people, not to everyone. Put the file in an `hr` group and let
only that group read it:

```
lab> chown root:hr salaries.csv
lab> chmod 640 salaries.csv
```

Now `640` means: owner can read/write, **the hr group can read**, others get nothing. Add jane to hr:

```
lab> addgroup jane hr
lab> read jane salaries.csv
lab> read rico salaries.csv
```

> **Q4.** Can jane read the file now? Can rico? Explain how jane got access **without** the file being
> readable by everyone. This is **least privilege** — access limited to exactly who needs it.

---

## Phase 4: One person, without a group (ACLs)

Sometimes you need to grant just **one** extra person, and making a whole group is overkill. A
**POSIX ACL** grants a single user directly:

```
lab> grant carlos salaries.csv
lab> read carlos salaries.csv
lab> perms salaries.csv
```

> **Q5.** carlos can now read the file even though he's not in the hr group. In the `perms` output,
> find the line that grants carlos access (`user:carlos:r--`). Also, `files` now shows a `+` after the
> permissions — what does that `+` tell an administrator at a glance?

Remove it again when carlos no longer needs it:

```
lab> revoke carlos salaries.csv
lab> read carlos salaries.csv
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

Type `quit` to leave (say `y` to shut the machine down). Your changes reset next time you start.

### Passport prompts (submit these)

Collect **Q1–Q7** into your lab journal, with:

- What `-rw-r-----` means, broken down into owner/group/other.
- The result of `read rico salaries.csv` before and after `chmod 644`, and why 644 was wrong.
- How you gave jane access the *right* way, and proof rico still couldn't read it.
- One sentence defining **least privilege** in your own words.

---

## Under the hood

Every console command is a standard Linux command:

| Console | Real command |
|---------|--------------|
| `read jane salaries.csv` | `runuser -u jane -- cat /office/salaries.csv` |
| `chmod 640 salaries.csv` | `chmod 640 /office/salaries.csv` |
| `chown root:hr salaries.csv` | `chown root:hr /office/salaries.csv` |
| `addgroup jane hr` | `usermod -aG hr jane` |
| `grant carlos salaries.csv` | `setfacl -m u:carlos:r /office/salaries.csv` |
| `perms salaries.csv` | `ls -l` + `getfacl` |

After `connect station` you're root — run these yourself and inspect `/office`.

### Instructor notes

- The naive `chmod 644` in Phase 2 is deliberate: seeing rico suddenly able to read the salaries is
  the module's key "aha". Have students undo it via the group approach.
- Maps directly onto the original NTFS lab (deny `rico`, grant via a group), then adds ACLs and the
  least-privilege framing.
- Changes are per-container and reset on restart, so students can experiment freely.
