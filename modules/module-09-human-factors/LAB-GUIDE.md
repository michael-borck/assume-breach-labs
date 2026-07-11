# Module 09 — Human Factors (Lab Guide)

**What this replaces:** the old lab's external OpenDNS and eSafety quizzes, and the badssl.com
certificate-warning site.
**What you actually use:** a self-hosted awareness quiz and your own broken-certificate test sites —
all running locally, offline.

Most breaches don't start with clever hacking; they start with a person clicking, trusting, or
ignoring a warning. This module is about *you* — spotting manipulation, and taking browser warnings
seriously.

## Getting in

```bash
./start.sh
```

Pick module `09`. This lab is entirely in your browser. Two parts:

- **Awareness quiz** — type `open` (or visit **http://localhost:8090**)
- **Broken-certificate sites** — type `certs` to list them

---

## Part A: The awareness quiz

```
lab> open
```

Work through the quiz — phishing emails and texts to judge, plus everyday security choices. Choose an
answer for each, then click **Score my answers**. Read the explanation under every question, right or
wrong — that's where the learning is.

> **Q1.** What was your score out of 8? Which question did you find hardest to judge, and why?

> **Q2.** In the first phishing example, the sender domain was `paypa1-secure.com`. What exactly is
> wrong with that domain, and why is it easy to miss at a glance?

> **Q3.** One email in the quiz was **legitimate**. What features made it safe — and why is it just as
> important to *not* cry wolf on genuine messages as it is to catch fakes?

> **Q4.** Two questions were about someone contacting *you* (a phone call from "IT", a found USB
> stick). What do these social-engineering tricks rely on in the victim — and what's the single
> safest habit that defeats both?

---

## Part B: Certificate warnings

When a website's certificate is broken, your browser stops and warns you. People are trained by
annoyance to click straight through these — which is exactly what an attacker counts on. Let's see the
real warnings. List the sites:

```
lab> certs
```

Visit each one in your browser. **Each will show a warning** — that's the point. Read the warning
carefully *before* clicking through.

- `https://localhost:8443` — an **expired** certificate
- `https://localhost:8444` — a **self-signed / untrusted** certificate
- `https://localhost:8445` — a certificate for the **wrong hostname**

> **Q5.** For each of the three sites, write down the exact warning wording (or the error code, e.g.
> `NET::ERR_CERT_DATE_INVALID`) your browser showed. They are **different** — match each site to its
> message.

> **Q6.** What is each certificate actually promising, and what does the flaw break?
> - expired: why does an out-of-date certificate stop being trustworthy?
> - self-signed: anyone can make one — so what does it fail to prove?
> - wrong hostname: the certificate is valid, so why is it still a problem here?

> **Q7.** You're about to log into your bank and see one of these warnings. Give the one-sentence rule
> you should follow — and explain what the warning might mean is happening to your connection.

> **Q8.** Browsers make you click through a warning on purpose (it's deliberately awkward). Is that
> good design or bad design? Argue your view in two or three sentences, using what you just saw.

---

## Wrapping up

Close the browser tabs and type `quit` in the console (say `y` to shut the machines down).

### Passport prompts (submit these)

Collect **Q1–Q8** into your lab journal, with:

- Your quiz score and the one explanation that surprised you most.
- What was wrong with the `paypa1-secure.com` domain.
- The three certificate warnings, matched to expired / self-signed / wrong-hostname.
- Your one-sentence rule for what to do when a warning appears on a site that matters.

---

## Notes

- The quiz and the certificate sites all run locally from this lab — nothing you do is sent anywhere,
  and it works with no internet connection.
- The certificates are generated fresh each time the lab starts, so the "expired" one is always
  genuinely expired.
- **Optional enrichment (needs internet):** the government-run
  [eSafety quizzes](https://www.esafety.gov.au) are worth trying too, but they're external and not
  required for this lab.

### Instructor notes

- The certificate sites are a self-hosted stand-in for badssl.com — three distinct failure modes so
  students see that "certificate warning" isn't one thing. Chrome shows a full-page interstitial and
  makes them click through; that friction is the teaching point of Q8.
- The quiz is self-contained HTML (no backend, no tracking); edit `quiz/index.html` to add questions.
- The two external quizzes from the original lab are kept only as optional enrichment links, since we
  can't self-host third-party content — the graded hands-on weight is on the self-hosted pieces.
