#!/usr/bin/env python3
"""Build the stylometry corpus for Module 08 from the public-domain Federalist
Papers (Project Gutenberg #1404). Splits papers by author and writes training
samples plus one held-out 'unknown' paper.

Usage:  python3 generate-corpus.py <federalist-text-file> <output-dir>
"""
import re, sys, collections

src = sys.argv[1] if len(sys.argv) > 1 else "/tmp/fed.txt"
out = sys.argv[2] if len(sys.argv) > 2 else "station/data/texts"
text = open(src, encoding="utf-8", errors="ignore").read()

# Split into papers on "FEDERALIST No. N"
marks = list(re.finditer(r'FEDERALIST\s+No\.?\s+(\d+)', text))
papers = {}
for i, m in enumerate(marks):
    n = int(m.group(1))
    start = m.end()
    end = marks[i + 1].start() if i + 1 < len(marks) else len(text)
    block = text[start:end]
    # Author is the first HAMILTON/MADISON/JAY token near the top of the block.
    head = "\n".join(block.splitlines()[:8]).upper()
    if "MADISON" in head and "HAMILTON" in head:
        author = "DISPUTED"
    elif "HAMILTON" in head:
        author = "HAMILTON"
    elif "MADISON" in head:
        author = "MADISON"
    elif "JAY" in head:
        author = "JAY"
    else:
        author = "?"
    # Body: drop the first couple of lines (title/author/"To the People...")
    body = "\n".join(block.splitlines()[3:])
    papers[n] = (author, body.strip())

counts = collections.Counter(a for a, _ in papers.values())
print("papers parsed:", len(papers), "| authors:", dict(counts))

def corpus(nums):
    return "\n\n".join(papers[n][1] for n in nums if n in papers)

# Training sets: clearly-attributed papers for each author.
HAM = [1, 6, 7, 8, 9, 11, 12, 13, 15, 16]
MAD = [10, 14, 37, 38, 39, 40, 41, 42, 43, 44]
JAY = [2, 3, 4, 5, 64]
UNKNOWN = 51   # Madison's famous "if men were angels" paper — held out

for name, nums in [("hamilton", HAM), ("madison", MAD), ("jay", JAY)]:
    txt = corpus(nums)
    open(f"{out}/{name}.txt", "w").write(txt)
    print(f"  {name}.txt: papers {nums} -> {len(txt.split())} words "
          f"(authors: {set(papers[n][0] for n in nums if n in papers)})")

open(f"{out}/unknown.txt", "w").write(papers[UNKNOWN][1])
print(f"  unknown.txt: paper {UNKNOWN} -> {len(papers[UNKNOWN][1].split())} words "
      f"(TRUE author in source: {papers[UNKNOWN][0]})")
