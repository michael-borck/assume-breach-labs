# Module 04 — Cryptography (Lab Guide)

**What this replaces:** the old lab's web tools (rumkin.com cipher tool, pgpkeygen.com,
onlinepgp.com).
**What you actually use:** a small cipher tool for the classic ciphers, and **real GnuPG (PGP)** for
public-key cryptography — all offline, on your own workstation.

You drive everything from the lab console; you won't type Docker. Each command shows the real command
it runs so you learn the tools — see [Under the hood](#under-the-hood-the-real-commands).

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

Pick module `04`. At the `lab>` prompt (`help` for the list):

**Part A — classic ciphers:** `challenge`, `caesar break <text>`, `caesar shift <n> <text>`,
`atbash <text>`
**Part B — public-key (PGP):** `keygen`, `keys`, `encrypt bob <message>`, `decrypt`,
`sign <message>`, `verify`, `tamper`

---

## Part A — Classic ciphers

### Phase 1: Break a Caesar cipher

A **Caesar cipher** shifts each letter along the alphabet by a fixed amount. There are only 25
possible shifts — so a computer breaks it instantly by trying them all. You intercepted a message:

```
lab> challenge
```

Crack it by trying every shift:

```
lab> caesar break <paste the ciphertext here>
```

> **Q1.** What was the original message, and what shift was used? How did you know which of the 25
> lines was the right one? (This trying-everything approach is called a **brute-force** attack — the
> same idea as the password cracking in Module 03.)

> **Q2.** A Caesar cipher is one kind of **monoalphabetic substitution cipher** — each letter always
> maps to the same other letter. In one sentence, why is *any* such cipher weak, even one with a
> random letter mapping rather than a simple shift? (Hint: which letters are most common in English?)

### Phase 2: The Atbash cipher

Atbash maps A↔Z, B↔Y, C↔X, and so on. Try it:

```
lab> atbash CRYPTOGRAPHY
```

> **Q3.** Run `atbash` on the *output* you just got. What happens, and why? (What does that tell you
> about Atbash's "key"?)

---

## Part B — Public-key cryptography (PGP)

Classic ciphers use one secret shared by both sides. **Public-key** cryptography gives each person
*two* keys: a **public** key anyone can have (used to encrypt *to* them, or to check *their*
signature) and a **private** key they keep secret (used to decrypt, or to sign).

### Phase 3: Make the keys

Create key pairs for two people, Alice and Bob:

```
lab> keygen
lab> keys
```

> **Q4.** Each person now has a **public** and a **private** key. Which key would Alice publish on her
> website, and which would she guard with her life? What happens if someone steals her *private* key?

### Phase 4: Encrypt a message only Bob can read

Encrypt a message to Bob — this uses **Bob's public key**:

```
lab> encrypt bob meet at the docks at midnight
```

You'll see the scrambled `PGP MESSAGE` block. Now decrypt it — this needs **Bob's private key**,
which is on this machine:

```
lab> decrypt
```

> **Q5.** The message was encrypted with Bob's *public* key but can only be decrypted with his
> *private* key. Why is it safe for Alice to encrypt using a key (Bob's public key) that *everyone*,
> including an attacker, can see? What does the attacker still lack?

> **Q6 (the "wrong key" problem).** Suppose an attacker, Mallory, tricks Alice into using *Mallory's*
> public key while believing it's Bob's. Who can now read the message Alice thought she was sending to
> Bob? This is why verifying that a public key really belongs to who you think is critical.

### Phase 5: Signing — proving who sent it

Encryption hides a message; a **signature** proves *who wrote it* and that it wasn't changed. Alice
signs a message with her **private** key; anyone can check it with her **public** key:

```
lab> sign I approve the transfer
lab> verify
```

> **Q7.** `verify` reports a "Good signature from Alice". What two things does a valid signature prove?
> Could anyone *other* than Alice have produced it, and why not?

### Phase 6: Tampering breaks it

Encryption also protects **integrity**. Change even one character of an encrypted message and it
won't decrypt:

```
lab> encrypt bob the account number is 4471
lab> tamper
```

> **Q8.** What happened when you tried to decrypt the altered message? Why is it a *good* thing that a
> single flipped character makes decryption fail outright, rather than producing slightly-wrong text?

---

## Wrapping up

Type `quit` to leave (say `y` to shut the machine down).

### Passport prompts (submit these)

Collect **Q1–Q8** into your lab journal, with:

- The cracked Caesar message and its shift.
- One sentence explaining the difference between the Caesar cipher's key and a PGP private key.
- A note of which key encrypts, which decrypts, which signs, and which verifies (the four roles).
- What the `tamper` step showed about integrity.

---

## Under the hood: the real commands

You never typed Docker; everything ran real tools on the workstation:

| Console command | Real command it ran |
|-----------------|---------------------|
| `caesar break <text>` | `cipher break <text>` (tries all 25 shifts) |
| `atbash <text>` | `cipher atbash <text>` |
| `keygen` | `gpg --batch --gen-key` for Alice and Bob |
| `keys` | `gpg --list-keys` |
| `encrypt bob <msg>` | `gpg --armor -r bob@lab -e` |
| `decrypt` | `gpg -d message.asc` |
| `sign <msg>` | `gpg --clearsign -u alice@lab` |
| `verify` | `gpg --verify signed.asc` |

After `connect station` you can run `gpg` yourself. Real-world note: PGP/GnuPG is exactly what's used
to sign software releases and encrypt email — the same commands, just with real people's keys.

### Instructor notes

- Keys are generated with `%no-protection` (no passphrase) so the lab flows without pinentry prompts;
  mention that real keys are passphrase-protected.
- Both identities live in one keyring, so `decrypt`/`verify` "just work" — the point is the
  public/private *roles*, not multi-user key exchange (that's a natural extension).
- `tamper` flips a character in the armored ciphertext; the armor CRC catches it (`gpg: CRC error`),
  which is the integrity lesson.
- Everything is offline; no external crypto website is used (unlike the original lab).
