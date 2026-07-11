#!/usr/bin/env python3
"""Stylometry — guess who wrote a document by its writing style.

Compares an unknown text against known author samples using the distribution of
word lengths (a classic authorship signal). Lower chi-square = closer style.

Usage:
  stylometry.py <texts-dir> [unknown-file]
Defaults to /home/analyst/lab/texts and unknown.txt.
"""
import sys, os, re, collections

MAXLEN = 15

def words(t):
    return re.findall(r"[A-Za-z]+", t)

def sentences(t):
    return [s for s in re.split(r"[.!?]+", t) if s.strip()]

def wl_counts(ws):
    return collections.Counter(min(len(w), MAXLEN) for w in ws)

def distribution(ws):
    c = wl_counts(ws); total = sum(c.values())
    return {k: c.get(k, 0) / total for k in range(1, MAXLEN + 1)}

def chi_square(unknown_ws, ref_dist):
    c = wl_counts(unknown_ws); total = sum(c.values())
    x = 0.0
    for k in range(1, MAXLEN + 1):
        e = ref_dist[k] * total
        if e > 0:
            x += (c.get(k, 0) - e) ** 2 / e
    return x

def summary(ws):
    sents = max(1, len(sentences(" ".join(ws) if isinstance(ws, list) else ws)))
    mwl = sum(len(w) for w in ws) / max(1, len(ws))
    return mwl

def main():
    d = sys.argv[1] if len(sys.argv) > 1 else "/home/analyst/lab/texts"
    unk = sys.argv[2] if len(sys.argv) > 2 else "unknown.txt"
    unk_path = os.path.join(d, unk)
    unk_text = open(unk_path, encoding="utf-8", errors="ignore").read()
    unk_words = words(unk_text)

    authors = sorted(f for f in os.listdir(d)
                     if f.endswith(".txt") and f != unk and not f.startswith("."))

    print(f"Unknown document: {unk}  ({len(unk_words)} words, "
          f"avg word length {sum(len(w) for w in unk_words)/len(unk_words):.2f})\n")
    print(f"{'candidate author':<16}{'avg word len':>14}{'chi-square vs unknown':>24}")
    print("-" * 54)

    results = []
    for a in authors:
        atext = open(os.path.join(d, a), encoding="utf-8", errors="ignore").read()
        aws = words(atext)
        x = chi_square(unk_words, distribution(aws))
        avg = sum(len(w) for w in aws) / len(aws)
        results.append((a, avg, x))

    for a, avg, x in results:
        print(f"{a.replace('.txt',''):<16}{avg:>14.2f}{x:>24.3f}")

    best = min(results, key=lambda r: r[2])
    print("\n" + "=" * 54)
    print(f"Closest match: {best[0].replace('.txt','').upper()} "
          f"(lowest chi-square = {best[2]:.3f})")
    print("The unknown document's word-length pattern is most similar to this author.")

if __name__ == "__main__":
    main()
