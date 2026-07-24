# Module 04 — Cryptography (Lab Guide)

**What this replaces:** the old lab's web tools (rumkin.com cipher tool, pgpkeygen.com,
onlinepgp.com).
**What you actually use:** a small cipher tool for the classic ciphers, and **real GnuPG (PGP)** for
public-key cryptography — all offline, on your own workstation.

You are the **analyst** at a crypto workstation. Everything below is a real command — the same
`cipher` and `gpg` tools that run on real systems — so run them yourself, inspect the output, and
because they're genuine (not lab shortcuts), feel free to ask an AI assistant to explain anything you
don't recognise.

## Lab Scenario

Two parts. First you break a **classic cipher** by hand to see why simple substitution is hopeless
against a computer. Then you use **public-key cryptography** the way it's actually used — two people,
Alice and Bob, exchanging a message that only the intended recipient can read, and a signature that
proves who sent it. The defensive lesson runs through both: what makes encryption weak, and what a
key actually protects.

## Getting in

```bash
./start.sh
```

Pick module `04`. The workstation powers on and **logs you straight in as `analyst`** on the crypto
workstation — a real Linux shell, in `/home/analyst/lab`. Type **`labhelp`** any time for the mission
and the commands you'll need.

The `cipher` tool and `gpg` are on your PATH; the intercepted message is `challenge.txt` in your
working directory.

---

## Part A — Classic ciphers

### Phase 1: Break a Caesar cipher

A **Caesar cipher** shifts each letter along the alphabet by a fixed amount. There are only 25
possible shifts — so a computer breaks it instantly by trying them all. You intercepted a message:

```bash
cat challenge.txt
```

Crack it by trying every shift (the `"$(cat challenge.txt)"` part just feeds the ciphertext straight
in — you could also paste the text yourself):

```bash
cipher break "$(cat challenge.txt)"
```

> **Q1.** What was the original message, and what shift was used? How did you know which of the 25
> lines was the right one? (This trying-everything approach is called a **brute-force** attack — the
> same idea as the password cracking in Module 03.)

> **Q2.** A Caesar cipher is one kind of **monoalphabetic substitution cipher** — each letter always
> maps to the same other letter. In one sentence, why is *any* such cipher weak, even one with a
> random letter mapping rather than a simple shift? (Hint: which letters are most common in English?)

You can also shift text yourself in either direction — forward by 3, or back by 3 to undo it:

```bash
cipher shift 3 HELLO
cipher shift -3 KHOOR
```

### Phase 2: The Atbash cipher

Atbash maps A↔Z, B↔Y, C↔X, and so on. Try it:

```bash
cipher atbash CRYPTOGRAPHY
```

> **Q3.** Run `cipher atbash` on the *output* you just got. What happens, and why? (What does that
> tell you about Atbash's "key"?)

---

## Part B — Public-key cryptography (PGP)

Classic ciphers use one secret shared by both sides. **Public-key** cryptography gives each person
*two* keys: a **public** key anyone can have (used to encrypt *to* them, or to check *their*
signature) and a **private** key they keep secret (used to decrypt, or to sign).

### Phase 3: Make the keys

Create key pairs for two people, Alice and Bob. The helper script runs the real
`gpg --batch --gen-key` for each of them:

```bash
sh make-keys.sh
gpg --list-keys
```

> **Q4.** Each person now has a **public** and a **private** key. Which key would Alice publish on her
> website, and which would she guard with her life? What happens if someone steals her *private* key?

### Phase 4: Encrypt a message only Bob can read

Encrypt a message to Bob — this uses **Bob's public key** (`-r bob@lab` picks him as the recipient,
`-e` encrypts, `--armor` gives readable text output):

```bash
printf '%s' "meet at the docks at midnight" \
  | gpg --yes --armor --trust-model always -r bob@lab -e -o message.asc
cat message.asc
```

You'll see the scrambled `PGP MESSAGE` block. Now decrypt it — this needs **Bob's private key**,
which is on this machine:

```bash
gpg --yes -d message.asc
```

> **Q5.** The message was encrypted with Bob's *public* key but can only be decrypted with his
> *private* key. Why is it safe for Alice to encrypt using a key (Bob's public key) that *everyone*,
> including an attacker, can see? What does the attacker still lack?

> **Q6 (the "wrong key" problem).** Suppose an attacker, Mallory, tricks Alice into using *Mallory's*
> public key while believing it's Bob's. Who can now read the message Alice thought she was sending to
> Bob? This is why verifying that a public key really belongs to who you think is critical.

### Phase 5: Signing — proving who sent it

Encryption hides a message; a **signature** proves *who wrote it* and that it wasn't changed. Alice
signs a message with her **private** key (`-u alice@lab`); anyone can check it with her **public** key:

```bash
printf '%s' "I approve the transfer" \
  | gpg --yes --clearsign -u alice@lab -o signed.asc
gpg --verify signed.asc
```

> **Q7.** `gpg --verify` reports a "Good signature from Alice". What two things does a valid signature
> prove? Could anyone *other* than Alice have produced it, and why not?

### Phase 6: Tampering breaks it

Encryption also protects **integrity**. Change even one character of an encrypted message and it
won't decrypt. Re-encrypt something, flip a single character in the ciphertext, then try to read it:

```bash
printf '%s' "the account number is 4471" \
  | gpg --yes --armor --trust-model always -r bob@lab -e -o message.asc
sed -i '3s/./X/' message.asc
gpg --yes -d message.asc
```

> **Q8.** What happened when you tried to decrypt the altered message? Why is it a *good* thing that a
> single flipped character makes decryption fail outright, rather than producing slightly-wrong text?

---

## Wrapping up

Type `exit` to leave (say `y` to shut the machine down). Your changes reset next time you start.

### Passport prompts (submit these)

Collect **Q1–Q8** into your lab journal, with:

- The cracked Caesar message and its shift.
- One sentence explaining the difference between the Caesar cipher's key and a PGP private key.
- A note of which key encrypts, which decrypts, which signs, and which verifies (the four roles).
- What the tampering step showed about integrity.

---

## Command reference

Every command in this lab is a real tool you'll use on real systems:

| Task | Command |
|------|---------|
| Show the intercepted ciphertext | `cat challenge.txt` |
| Try all 25 Caesar shifts (crack it) | `cipher break "$(cat challenge.txt)"` |
| Shift text by n (use `-n` to shift back) | `cipher shift 3 HELLO` |
| Apply the Atbash cipher | `cipher atbash CRYPTOGRAPHY` |
| Create Alice's and Bob's key pairs | `sh make-keys.sh` |
| List keys in the keyring | `gpg --list-keys` |
| Encrypt so only Bob can read it | `printf '%s' "msg" \| gpg --yes --armor --trust-model always -r bob@lab -e -o message.asc` |
| Decrypt (needs Bob's private key) | `gpg --yes -d message.asc` |
| Sign a message as Alice | `printf '%s' "msg" \| gpg --yes --clearsign -u alice@lab -o signed.asc` |
| Verify a signature | `gpg --verify signed.asc` |
| Tamper with one character | `sed -i '3s/./X/' message.asc` |

Real-world note: PGP/GnuPG is exactly what's used to sign software releases and encrypt email — the
same commands, just with real people's keys. Run these yourself, inspect the results, and don't be
afraid to break things. Everything resets when you restart the lab.
