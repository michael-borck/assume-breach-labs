# Schedule Mapping

This repo is **unit-agnostic**: modules are numbered by topic. Map them onto whatever teaching
calendar you're running by editing the right-hand columns of this one file. Nothing else in the
repo references week numbers or dates.

## Modules → teaching weeks

The mapping below reflects a typical 13-week semester with a lecture + 1-hour workshop each week,
one tuition-free week, and no workshop in the catch-up week. Adjust to your own calendar.

| Module | Topic | Teaching week | Workshop | Notes |
|--------|-------|---------------|----------|-------|
| 00 | Environment setup | Before Week 1 / Week 1 | Orientation | Do once; not a graded lab |
| 01 | Access control & isolation | Week 1 | Workshop 1 | Replaces "intro to virtualisation" |
| 02 | Port scanning & enumeration | Week 2 | Workshop 2 | Scans internal lab hosts only |
| 03 | Password attacks | Week 3 | Workshop 3 | |
| 04 | Cryptography | Week 4 | Workshop 4 | |
| 05 | Risk management | Week 5 | Workshop 5 | In-browser SLE/ALE calculator |
| — | Catch-up + assignment | Week 6 | (no new lab) | |
| — | *Tuition-free week* | Week 7 | — | |
| 06 | Packet capture & analysis | Week 8 | Workshop 6 (Lab 7) | Lab numbering runs one behind week numbering from here |
| 07 | Firewalls | Weeks 9–10 | Workshops 7–8 (Labs 8–9) | Spans two workshops |
| 08 | Digital forensics | Week 11 | Workshop 9 (Lab 10) | Report/assessment week |
| 09 | Human factors | Week 12 | Workshop 10 | |
| — | Revision | Week 13 | — | |

> **Two quirks to preserve if you keep this cadence:** there is no Week 7 (tuition-free), and the
> firewall module deliberately spans two workshops. Directories here are named by **module**;
> your worksheets/passport can be named by **workshop/lab number**.

## Assessment tie-in

Each module's `LAB-GUIDE.md` ends with **passport prompts** (the record / screenshot / answer
steps). Those feed a lab-journal / passport assessment without this repo needing to know anything
about the unit's grading.
