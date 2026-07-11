# Module 03 — Password Attacks (Lab Guide)

**What this replaces:** the old Windows-only lab that used L0phtcrack, L517, and fcrackzip inside
the XP VM, plus web hash tools.
**What you actually use:** the real tools professionals use — **John the Ripper** (hash cracking)
and **fcrackzip** (archive cracking) — on a real Linux workstation.

You drive everything from the lab console. You will *not* type Docker commands: you log in, then use
plain commands like `crack easy` and `crackzip`. Each command shows the real tool it runs (e.g.
`[station] $ john --format=raw-md5 ...`) so you still learn the real thing — see
[Under the hood](#under-the-hood-the-real-commands).

## Lab Scenario

You've obtained a set of leaked password **hashes** and a **password-protected archive** from a
compromised system. Your task, as an authorised tester, is to find out how many of the passwords are
weak enough to crack — and to understand *why* some fall in milliseconds and others would take
centuries. The lesson is defensive: if you can crack it this easily, so can an attacker, so these are
the passwords your policy must forbid.

## Getting in

```bash
./start.sh
```

Pick module `03` if prompted. You'll land at a `lab>` prompt. Type `help` any time. The commands:

| Command | What it does |
|---------|--------------|
| `hashes` | Show the hash files you'll attack |
| `identify <hash>` | Guess a hash's type from its shape |
| `crack easy` | Crack the MD5 hashes with a wordlist |
| `crack sha` | Crack the SHA-256 hashes |
| `crack windows` | Crack the Windows NTLM hashes |
| `crackzip` | Dictionary-attack the password-protected zip |
| `openzip <password>` | Open the zip once you've cracked its password |
| `connect station` | Drop into the workstation shell to run tools yourself |

---

## Phase 1: What kind of hash is this?

Before cracking, you need to know what you're looking at. Look at the hashes:

```
lab> hashes
```

You'll see three files: MD5 (32 hex characters), SHA-256 (64), and Windows NTLM (in `pwdump`
format). Try identifying one:

```
lab> identify 5f4dcc3b5aa765d61d8327deb882cf99
```

> **Q1.** How does a tool guess a hash's *type* without knowing the password? What property of the
> hash gives it away? (Hint: look at the lengths of the three hash files.)

> **Q2.** The identifier says a 32-character hex string could be **MD5 or NTLM**. Why can't length
> alone tell them apart, and what extra information would you need?

---

## Phase 2: Cracking with a wordlist (dictionary attack)

A **dictionary attack** tries a list of likely passwords and hashes each one, looking for a match. It
only finds passwords that are *in the list* — but weak passwords almost always are.

```
lab> crack easy
```

John hashes each word in the wordlist and compares. Watch it find the weak ones instantly.

> **Q3.** How many of the MD5 hashes cracked, and what were the passwords? Roughly how long did it
> take?

Now the other two sets:

```
lab> crack sha
lab> crack windows
```

> **Q4.** The Windows NTLM crack shows a **username** next to each password (e.g.
> `Administrator:Password1`). Which account had the weakest password? Why is a weak *Administrator*
> password far more dangerous than a weak ordinary-user password?

> **Q5.** A dictionary attack only cracks passwords that are in the wordlist. Name two passwords that
> would *survive* this attack, and say what makes them resistant.

---

## Phase 3: Why length beats complexity (a thinking exercise)

A **brute-force** attack tries *every* combination, not just a wordlist. Its cost grows with the
number of possibilities, which is `(size of character set) ^ (length)`.

Fill in this table (a calculator is fine):

| Password | Character set | Length | Combinations |
|----------|---------------|--------|--------------|
| `cat` | 26 lowercase | 3 | 26³ = 17,576 |
| `password` | 26 lowercase | 8 | 26⁸ = ? |
| `Xk9` | 62 (upper+lower+digits) | 3 | 62³ = ? |
| `correcthorsebatterystaple` | 26 lowercase | 25 | 26²⁵ = ? |

> **Q6.** Compare `Xk9` (short but complex) with `correcthorsebatterystaple` (long but all
> lowercase). Which has more combinations? What does this tell you about the advice "use a longer
> passphrase" versus "add a symbol"?

---

## Phase 4: Cracking a password-protected archive

Files can be encrypted with a password too — and the same dictionary attack applies.

```
lab> crackzip
```

fcrackzip tries each word in the list against the archive.

> **Q7.** What password protected the archive? Once you have it, open the file and read what's
> inside:
> ```
> lab> openzip <the-password-you-found>
> ```
> Record the flag from `flag.txt`.

---

## Wrapping up

Type `quit` to leave (say `y` to shut the machine down).

### Passport prompts (submit these)

Collect **Q1–Q7** into your lab journal, with:

- The list of cracked passwords from Phase 2 (all three hash types).
- Your completed combinations table from Phase 3.
- The archive password and the flag from Phase 4.
- Two sentences: based on what you saw, what **two rules** would you put in a password policy to
  defeat the attacks you just ran?

---

## Under the hood: the real commands

You never typed Docker, but every step ran real tools. Here's the equivalent you could run on any
Linux system after `connect station`:

| Console command | Real command it ran |
|-----------------|---------------------|
| `crack easy` | `john --format=raw-md5 --wordlist=wordlists/common-passwords.txt hashes/easy-md5.txt` |
| `crack sha` | `john --format=raw-sha256 --wordlist=... hashes/medium-sha256.txt` |
| `crack windows` | `john --format=NT --wordlist=... hashes/windows-ntlm.txt` |
| `crackzip` | `fcrackzip -D -p wordlists/common-passwords.txt -u secret.zip` |
| `identify <hash>` | `identify-hash <hash>` (a small teaching script) |
| show cracked again | `john --show --format=<fmt> <hashfile>` |

Try `connect station` and run `john --show --format=NT hashes/windows-ntlm.txt` yourself — you'll see
the full recovered credentials. The real rockyou wordlist is also on the machine at
`/usr/share/wordlists/rockyou.txt` if you want a bigger dictionary.
