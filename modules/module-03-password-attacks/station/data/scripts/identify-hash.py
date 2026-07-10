#!/usr/bin/env python3
"""Guess a hash type from its length/shape. A teaching aid, not a forensic tool."""
import sys, re

def identify(h):
    h = h.strip()
    guesses = []
    if re.fullmatch(r"[0-9a-fA-F]+", h):
        n = len(h)
        by_len = {
            16: "LM half / DES",
            32: "MD5  (or NTLM — both 32 hex chars; context decides)",
            40: "SHA-1",
            56: "SHA-224",
            64: "SHA-256",
            96: "SHA-384",
            128: "SHA-512",
        }
        guesses.append(by_len.get(n, f"unknown hex hash ({n} chars)"))
    if h.startswith("$2"):   guesses.append("bcrypt")
    if h.startswith("$6$"):  guesses.append("sha512crypt (/etc/shadow)")
    if h.startswith("$1$"):  guesses.append("md5crypt")
    if ":" in h and re.search(r":[0-9a-fA-F]{32}:::", h):
        guesses.append("Windows pwdump line (LM:NTLM)")
    return guesses or ["unrecognised"]

if len(sys.argv) < 2:
    print("Usage: identify-hash.py <hash>")
    print("Example: identify-hash.py 5f4dcc3b5aa765d61d8327deb882cf99")
    sys.exit(1)

for h in sys.argv[1:]:
    print(f"{h}")
    for g in identify(h):
        print(f"   -> {g}")
