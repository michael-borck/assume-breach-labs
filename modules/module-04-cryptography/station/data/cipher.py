#!/usr/bin/env python3
"""Classic ciphers for Module 04. Teaching tool — not secure, that's the point.

Usage:
  cipher.py shift <n> <text...>   Caesar-shift text by n (use -n to shift back)
  cipher.py break <text...>       Try all 25 Caesar shifts (cryptanalysis)
  cipher.py atbash <text...>      Apply the Atbash cipher (its own inverse)
"""
import sys

def shift(text, n):
    out = []
    for ch in text:
        if ch.isupper():
            out.append(chr((ord(ch) - 65 + n) % 26 + 65))
        elif ch.islower():
            out.append(chr((ord(ch) - 97 + n) % 26 + 97))
        else:
            out.append(ch)
    return "".join(out)

def atbash(text):
    out = []
    for ch in text:
        if ch.isupper():
            out.append(chr(90 - (ord(ch) - 65)))
        elif ch.islower():
            out.append(chr(122 - (ord(ch) - 97)))
        else:
            out.append(ch)
    return "".join(out)

def main(argv):
    if len(argv) < 2:
        print(__doc__); return 1
    cmd = argv[1]
    if cmd == "shift":
        n = int(argv[2]); text = " ".join(argv[3:])
        print(shift(text, n))
    elif cmd == "break":
        text = " ".join(argv[2:])
        for n in range(1, 26):
            print(f"shift {n:2d}: {shift(text, -n)}")
    elif cmd == "atbash":
        text = " ".join(argv[2:])
        print(atbash(text))
    else:
        print(__doc__); return 1
    return 0

if __name__ == "__main__":
    sys.exit(main(sys.argv))
