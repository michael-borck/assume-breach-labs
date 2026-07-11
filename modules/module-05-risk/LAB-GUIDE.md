# Module 05 — Risk Management (Lab Guide)

**What this replaces:** the old Excel spreadsheet exercise (`lab-05-task-2.xlsx`).
**What you actually use:** an interactive risk calculator in your web browser — no spreadsheet, no
install.

This is the one module with no command line: you log in, the calculator starts, and you work in your
browser. The maths is the lesson, not the tool.

## Lab Scenario

You are advising **XYZ Software Company** on its security budget. You can't spend money on every
possible threat, so you need a way to decide *which* safeguards are worth buying. The standard method
is **quantitative risk analysis**: estimate what each threat costs per year, then only pay for a
control when it costs less than the loss it prevents.

Three numbers do the work:

| Term | Meaning |
|------|---------|
| **SLE** — Single Loss Expectancy | what **one** occurrence costs |
| **ARO** — Annualised Rate of Occurrence | how many times a **year** it happens (0.1 = once a decade) |
| **ALE** — Annualised Loss Expectancy | **SLE × ARO** — the expected yearly loss |

A control is **cost-justified** when its yearly cost is **less than the ALE** it removes.

## Getting in

```bash
./start.sh
```

Pick module `05`. When it's up, type `open` (or go to **http://localhost:8055**). The calculator loads
with XYZ's threat register already filled in.

---

## Phase 1: Read the register

Look down the table. Each row is a threat with its SLE, ARO, computed ALE, and the yearly cost of a
control that would remove it. The right-hand column shows whether that control is worth buying.

> **Q1.** Which single threat carries the **highest annual loss (ALE)**? Is it the one that costs the
> most per incident, or the one that happens most often? What does that tell you about focusing only on
> worst-case events?

> **Q2.** Write out the ALE formula and show the calculation for **"Viruses, worms, trojans"** using
> the values in the table. Check your answer against the ALE the calculator shows.

---

## Phase 2: Which controls are worth buying?

Look at the **Cost-justified?** column. Some controls save money; some cost more than the risk they
remove.

> **Q3.** Find one control marked **"Not worth it"**. What is its yearly cost, and what is the ALE it
> would remove? By how much would the company *lose* by buying it?

> **Q4.** "Software piracy" happens often (high ARO) but the control still isn't justified. Explain why
> a *frequent* threat can still be one you rationally choose **not** to spend money defending against.

> **Q5.** Read the three summary tiles at the top (total annual risk, recommended control spend, net
> saving). In one sentence, what is the company's best overall strategy — buy every control, or only
> the justified ones? What is the net saving if they follow the calculator's advice?

---

## Phase 3: Change the assumptions

The figures are estimates, and estimates change. Edit the numbers and watch the verdicts move.

> **Q6.** Pick a control currently marked **"Not worth it"**. Without changing its cost, how far would
> you have to raise the **ARO** (make the threat more frequent) before the control becomes justified?
> Explain what you changed and why it flipped.

> **Q7.** The "Fire" threat has a huge SLE but a tiny ARO. Lower the control cost or raise the ARO until
> it flips, then put it back. In real life, which of these two numbers is genuinely hard to estimate —
> and what does that uncertainty mean for decisions about rare, catastrophic events?

---

## Phase 4: The limits of the numbers

> **Q8.** Some losses don't fit neatly into a dollar SLE — reputation, customer trust, staff morale,
> legal exposure. Name one threat in the table whose *real* cost is probably **higher** than its SLE
> suggests, and explain how relying only on these numbers could lead a business to under-protect itself.

---

## Wrapping up

Close the browser tab and type `quit` in the console (say `y` to shut the machine down).

### Passport prompts (submit these)

Collect **Q1–Q8** into your lab journal, with:

- The ALE calculation for one threat, worked by hand.
- One control that is justified and one that isn't, with the numbers that make each decision.
- The company's net annual saving from following the justified-only strategy.
- Two sentences on where the quantitative method breaks down (Q8).

---

## Notes

- The calculator runs entirely in your browser from a page served on your own machine — nothing is
  sent anywhere, and it works offline.
- All figures are editable; refresh the page to reset to XYZ's starting numbers.
