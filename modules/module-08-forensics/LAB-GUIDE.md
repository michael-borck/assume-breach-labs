# Module 08 — Digital Forensics (Lab Guide)

**What this replaces:** the old lab's online email-header tools (gaijin.at, Google header analyser,
Talos) and the Windows-only *Signature* stylometry app.
**What you actually use:** two offline Python tools on a forensic workstation — `mailtrace` (email
header analysis) and `stylometry` (authorship attribution).

Two investigations. In the first you trace where an email *really* came from and catch a fake. In the
second you identify an anonymous author by their writing style — the classic technique behind real
"who wrote this?" cases.

## Getting in

```bash
./start.sh
```

Pick module `08`. At the `lab>` prompt (`help` for the list).

---

# Part A — Email forensics: catching a fake

Every email carries a stack of **headers** recording the servers it passed through and who claims to
have sent it. Attackers can forge the *displayed* sender, but the delivery path and the
authentication results are much harder to fake. Three messages arrived:

```
lab> emails
```

## Phase 1: A normal message

```
lab> headers legitimate
lab> trace legitimate
```

`trace` reads the headers, follows the delivery path to the **originating server**, checks the
sender's authentication (SPF/DKIM/DMARC), and gives a verdict.

> **Q1.** What is the originating IP address of this message? Do the `From`, `Reply-To`, and
> `Return-Path` all agree, and did SPF/DKIM/DMARC pass? Why does that combination make it look
> genuine?

## Phase 2: A phishing message

```
lab> trace phishing
```

> **Q2.** This message *displays* `From: PayPal Service <service@paypal.com>`. According to the
> trace, what domain did it **actually** come from (the Return-Path), and where would a **reply**
> go (the Reply-To)?

> **Q3.** List the red flags `trace` reported. Which single check most clearly proves the sender is
> lying about who they are? (Think about SPF: what does "the sending server is not authorised for
> that domain" mean?)

> **Q4.** A busy person sees "PayPal" and a scary subject and clicks. Name two things a normal user
> could look at — without any tools — that hint this is fake.

## Phase 3: Spam

```
lab> trace spam
```

> **Q5.** This message's SPF/DKIM/DMARC actually **pass** — the spammer really does own
> `mega-savings-offers.biz`. So how did the mail system still flag it? (Look at the spam score and
> the `To:` line.) What's the difference between a message that is *forged* and one that is merely
> *unwanted*?

---

# Part B — Authorship analysis: who wrote it?

People have measurable writing habits — average word length, sentence length, favourite words. These
"fingerprints" can reveal who wrote an anonymous document. This is a real forensic technique
(**stylometry**); its most famous use settled a 150-year argument about the Federalist Papers.

## Phase 4: The known authors

```
lab> authors
```

You have writing samples from three authors — **Hamilton**, **Madison**, and **Jay** — and one
**unknown** document whose author is disputed.

> **Q6.** Why does having *more* text from each known author make the identification more reliable?
> (What happens to a statistical fingerprint built from only a sentence or two?)

## Phase 5: Unmask the author

```
lab> whodunnit
```

This measures the unknown document's word-length pattern and compares it to each known author using a
**chi-square** score — the *lower* the score, the *closer* the writing styles.

> **Q7.** Which author does the tool identify, and what was their chi-square score compared with the
> runner-up? How confident does that gap make you?

> **Q8.** The unknown document really is Federalist Paper No. 51, historically attributed to
> **Madison** — which is what the tool found. Stylometry is powerful, but give one reason it could be
> **wrong**: name a situation where measuring writing style would point to the *wrong* author.

---

## Wrapping up

Type `quit` to leave (say `y` to shut the machine down).

### Passport prompts (submit these)

Collect **Q1–Q8** into your lab journal, with:

- The originating IP of each of the three emails.
- The phishing red flags, and the one you found most convincing.
- One sentence on the difference between spoofed mail and spam.
- The author `whodunnit` identified, the two chi-square scores, and one limitation of stylometry.

---

## Under the hood

| Console | Real command |
|---------|--------------|
| `trace phishing` | `mailtrace emails/phishing.eml` (parses headers with Python's `email` module) |
| `headers phishing` | prints the raw header block of the `.eml` file |
| `whodunnit` | `stylometry texts unknown.txt` (word-length chi-square vs each author) |

After `connect station` you can read the raw `.eml` files and the author texts, and run the tools
with your own arguments.

## Going further — Incident Zero

Enjoyed the investigation? Incident Zero's **Forensics** module has you chase attribution and rebuild an attack timeline under pressure — the same detective work, played as a game. ([Incident Zero](https://incidentzero.retroverse.studio/) — free, print-and-play.)
