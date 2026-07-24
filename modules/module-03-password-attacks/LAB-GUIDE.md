# Module 03 — Password Attacks (Lab Guide)

**What this replaces:** the old Windows-only lab that used L0phtcrack, L517, and fcrackzip inside
the XP VM, plus web hash tools.
**What you actually use:** the real tools professionals use — **John the Ripper** (hash cracking)
and **fcrackzip** (archive cracking) — on a real Linux workstation, run by hand.

You are an authorised penetration tester at a real cracking workstation. You log straight into its
shell and run the genuine tools yourself — no lab shortcuts, no wrapper prompts.

## Lab Scenario

You've obtained a set of leaked password **hashes** and a **password-protected archive** from a
compromised system. Your task is to find out how many of the passwords are weak enough to crack —
and to understand *why* some fall in milliseconds and others would take centuries. The lesson is
defensive: if you can crack it this easily, so can an attacker, so these are the passwords your
policy must forbid.

## Getting in

```bash
./start.sh
```

Pick module `03` if prompted. The workstation powers on and **logs you straight in** as the
`analyst` user on `station` — a real Linux shell, in `~/lab`. Type **`labhelp`** any time for the
mission and the exact commands you'll need.

Everything below is a real Linux command. Run them, inspect the output, and — because these are the
genuine tools, not lab shortcuts — feel free to ask an AI assistant to explain anything you don't
recognise. Take a look at what you've been handed first:

```bash
ls hashes wordlists
cat hashes/easy-md5.txt
```

---

## Phase 1: What kind of hash is this?

Before cracking, you need to know what you're looking at. Look at the three hash files — MD5
(32 hex characters), SHA-256 (64), and Windows NTLM (in `pwdump` format):

```bash
cat hashes/easy-md5.txt
cat hashes/medium-sha256.txt
cat hashes/windows-ntlm.txt
```

Now identify one by its shape (`identify-hash` is a small teaching script on the workstation):

```bash
identify-hash 5f4dcc3b5aa765d61d8327deb882cf99
```

> **Q1.** How does a tool guess a hash's *type* without knowing the password? What property of the
> hash gives it away? (Hint: compare the lengths of the three hash files.)

> **Q2.** The identifier says a 32-character hex string could be **MD5 or NTLM**. Why can't length
> alone tell them apart, and what extra information would you need?

---

## Phase 2: Cracking with a wordlist (dictionary attack)

A **dictionary attack** tries a list of likely passwords, hashes each one, and looks for a match. It
only finds passwords that are *in the list* — but weak passwords almost always are.

John the Ripper needs to be told which hash algorithm it's attacking, with `--format`. Start with the
MD5 set:

```bash
john --format=raw-md5 --wordlist=wordlists/common-passwords.txt hashes/easy-md5.txt
```

John hashes each word in the wordlist and compares. Watch it find the weak ones instantly. To
re-print what it cracked (John caches results, so a second run says "No password hashes left to
crack" — use `--show` instead):

```bash
john --format=raw-md5 --show hashes/easy-md5.txt
```

> **Q3.** How many of the MD5 hashes cracked, and what were the passwords? Roughly how long did it
> take?

Now the other two sets — same tool, different `--format`:

```bash
john --format=raw-sha256 --wordlist=wordlists/common-passwords.txt hashes/medium-sha256.txt
john --format=NT         --wordlist=wordlists/common-passwords.txt hashes/windows-ntlm.txt
john --format=NT --show hashes/windows-ntlm.txt
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

Files can be encrypted with a password too — and the same dictionary attack applies. `fcrackzip`
tries each word in the list against the archive (`-D` = dictionary mode, `-p` = wordlist). It prints
the match as `possible pw found: <word>`:

```bash
fcrackzip -D -p wordlists/common-passwords.txt secret.zip
```

You can also crack the archive with **John** — exactly the tool you used on the hashes. `zip2john`
turns the encrypted archive into a hash line, and John cracks it:

```bash
zip2john secret.zip > secret.hash
john --wordlist=wordlists/common-passwords.txt secret.hash
john --show secret.hash
```

> **Q7.** What password protected the archive? Once you have it, open the file and read what's
> inside. (`unzip` isn't installed on this box, so use Python's built-in `zipfile` to extract —
> replace `PASSWORD` with the word you found):
> ```bash
> python3 -c 'import zipfile; zipfile.ZipFile("secret.zip").extractall(pwd=b"PASSWORD")'
> cat flag.txt
> ```
> Record the flag from `flag.txt`.

---

## Wrapping up

Type `exit` to leave (say `y` to shut the machine down). Your changes reset next time you start.

### Passport prompts (submit these)

Collect **Q1–Q7** into your lab journal, with:

- The list of cracked passwords from Phase 2 (all three hash types).
- Your completed combinations table from Phase 3.
- The archive password and the flag from Phase 4.
- Two sentences: based on what you saw, what **two rules** would you put in a password policy to
  defeat the attacks you just ran?

---

## Command reference

Every command in this lab is a standard tool you'll use on real systems. You run them yourself in
`~/lab`; type `labhelp` on the workstation for the same list.

| Task | Command |
|------|---------|
| See the files you've been handed | `ls hashes wordlists` |
| Read a hash file | `cat hashes/easy-md5.txt` |
| Guess a hash's type by shape | `identify-hash 5f4dcc3b5aa765d61d8327deb882cf99` |
| Crack the MD5 hashes | `john --format=raw-md5 --wordlist=wordlists/common-passwords.txt hashes/easy-md5.txt` |
| Crack the SHA-256 hashes | `john --format=raw-sha256 --wordlist=wordlists/common-passwords.txt hashes/medium-sha256.txt` |
| Crack the Windows NTLM hashes | `john --format=NT --wordlist=wordlists/common-passwords.txt hashes/windows-ntlm.txt` |
| Re-print what John cracked | `john --format=NT --show hashes/windows-ntlm.txt` |
| Dictionary-attack the zip (fcrackzip) | `fcrackzip -D -p wordlists/common-passwords.txt secret.zip` |
| Crack the zip with John | `zip2john secret.zip > secret.hash && john --wordlist=wordlists/common-passwords.txt secret.hash` |
| Open the zip once you have the password | `python3 -c 'import zipfile; zipfile.ZipFile("secret.zip").extractall(pwd=b"<password>")'` |

A bigger, real dictionary lives on the machine at `/usr/share/wordlists/rockyou.txt` if you want to
try a larger attack. You are the `analyst` user on `station`, working in `~/lab` — run these
yourself, inspect the results, and don't be afraid to experiment. Everything resets when you restart
the lab.
