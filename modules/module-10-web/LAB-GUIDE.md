# Module 10 — Web Security (Lab Guide)

**What this replaces:** nothing — the old unit had no hands-on web-security lab. This is new.
**What you actually use:** a deliberately vulnerable web application (OWASP Juice Shop) in your
browser. No install, no command line.

The web is where most people are attacked, because it is where most people are. This lab lets
you *be* the attacker against a target that is built to be broken, so you can see exactly how the
flaws from the reading work — and, more importantly, what would have stopped each one.

> **The one rule:** everything here is legal and safe because the app is designed for it. These
> same actions against a real site you do not own are a crime. Practise only on targets you own
> or are given permission to test.

## Getting in

```bash
./start.sh
```

Pick module `10`. Give it about 20 seconds to start, then type `open` (or go to
**http://localhost:3010**). You'll see an online shop. It works like a normal site — and it is
riddled with the classic web vulnerabilities.

Keep your browser's **developer tools** open (F12) as you go; you'll use the network and console
tabs to see what's really happening.

---

## Phase 1: Injection — when data becomes commands

The login form builds a database query from what you type. If your input isn't kept separate from
the query, it becomes *part of the command*.

1. Go to the **Login** page.
2. In the email field, enter:  `' OR 1=1--`
3. Put anything in the password field and submit.

**Q1.** Whose account did you log in as, and why? What did the `' OR 1=1--` do to the query the
site ran?

**Q2.** This is **SQL injection**. In one sentence, what is the fix — how should the site have
handled your input so it could never become part of the command? *(Hint: the reading calls it
keeping data and code separate.)*

## Phase 2: Cross-site scripting (XSS) — running your code in someone's browser

The site displays things you type back to you (and sometimes to others) without treating them as
untrusted.

1. Use the **search** box at the top.
2. Search for:  `<iframe src="javascript:alert('XSS')">`
3. Watch what happens.

**Q3.** The alert box is trivial, but describe what a *real* attacker would do instead of popping
an alert — what could that injected script steal or do, running as the trusted site in a victim's
browser?

**Q4.** What is the defence? *(Hint: the reading calls it treating user content as untrusted and
encoding it on the way out.)*

## Phase 3: Broken authentication and session

After you log in, the site issues a **session token** that says "it's still me" on every request.

1. With developer tools open (Application ▸ Storage, or the Network tab), find the **token** your
   browser sends after logging in (Juice Shop uses a JWT in `Authorization` / local storage).
2. Notice that possessing that token *is* being logged in — no password required.

**Q5.** If an attacker stole that token (via the XSS in Phase 2, or by sniffing an unencrypted
connection), what could they do that they could not do with just your username? What could they
*not* do?

**Q6.** Name two defences that make a stolen token less dangerous. *(Hint: HTTPS, `HttpOnly`
cookies, short expiry, re-issuing on login.)*

## Phase 4: A web flaw is a privacy incident

Poke around for data the site should not be handing out — a confidential document, another
customer's details, an admin area. (Juice Shop hides several; even finding the *path* to one is
the point.)

**Q7.** You've now made a web app leak data three different ways. Explain, in your own words, why a
single injection or XSS flaw is not only a technical bug but a **legal** problem for the business
that runs the site. *(Tie it to breach notification from the reading.)*

---

## Wrap-up: put it in the Lab Passport

Everything you did today was one idea in three costumes: **the site trusted input it should not
have trusted.** For your Lab Passport entry, answer:

> You attacked a web app four ways today. Which single flaw would you fix *first* if you ran this
> business, and why?

## Clean up

Type `quit` to leave the console. To stop the container: `make stop` (or `make down`).
