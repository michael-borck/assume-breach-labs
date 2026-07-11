#!/usr/bin/env python3
"""Trace an email from its headers: where it really came from, and whether the
sender is who they claim to be. A local, offline version of the header-analysis
tools the old lab used online.

Usage:  mailtrace.py <email-file>
"""
import sys, re, email
from email.utils import parseaddr

def domain(addr):
    _, e = parseaddr(addr or "")
    return e.split("@")[-1].lower() if "@" in e else ""

def main():
    if len(sys.argv) < 2:
        print("usage: mailtrace.py <email-file>"); return 1
    msg = email.message_from_string(open(sys.argv[1], encoding="utf-8", errors="ignore").read())

    frm = msg.get("From", "")
    reply = msg.get("Reply-To", "")
    rpath = msg.get("Return-Path", "")
    subj = msg.get("Subject", "")
    received = msg.get_all("Received", [])

    print("=" * 60)
    print(f"From:        {frm}")
    print(f"Reply-To:    {reply or '(none)'}")
    print(f"Return-Path: {rpath or '(none)'}")
    print(f"Subject:     {subj}")

    # Delivery path — Received headers are stacked newest-first, so the LAST one
    # is the origin (the first server that handled the message).
    print("\nDelivery path (newest hop first):")
    for i, r in enumerate(received):
        first = " ".join(r.split())[:78]
        tag = "  <- origin" if i == len(received) - 1 else ""
        print(f"  {i+1}. {first}{tag}")

    origin_ip = ""
    if received:
        m = re.search(r"\[(\d{1,3}(?:\.\d{1,3}){3})\]", received[-1])
        origin_ip = m.group(1) if m else ""
    print(f"\nOriginating IP: {origin_ip or '(not found)'}")

    auth = msg.get("Authentication-Results", "")
    spf = re.search(r"spf=(\w+)", auth)
    dmarc = re.search(r"dmarc=(\w+)", auth)
    dkim = re.search(r"dkim=(\w+)", auth)
    spam = msg.get("X-Spam-Score") or (re.search(r"score=([\d.]+)", msg.get("X-Spam-Status", "")) or [None, None])[1]

    print("\nAuthentication:")
    print(f"  SPF:   {spf.group(1) if spf else 'n/a'}")
    print(f"  DKIM:  {dkim.group(1) if dkim else 'n/a'}")
    print(f"  DMARC: {dmarc.group(1) if dmarc else 'n/a'}")
    if spam:
        print(f"  Spam score: {spam}")

    # Red-flag checks
    flags = []
    fd, rd, rpd = domain(frm), domain(reply), domain(rpath)
    if fd and rpd and fd != rpd:
        flags.append(f"From domain ({fd}) != Return-Path domain ({rpd}) — envelope sender differs from displayed sender")
    if fd and rd and rd != fd:
        flags.append(f"Reply-To domain ({rd}) != From domain ({fd}) — replies would go elsewhere")
    if spf and spf.group(1).lower() == "fail":
        flags.append("SPF failed — the sending server is not authorised for that domain")
    if dmarc and dmarc.group(1).lower() == "fail":
        flags.append("DMARC failed — message fails the domain's anti-spoofing policy")
    try:
        if spam and float(spam) >= 5.0:
            flags.append(f"High spam score ({spam})")
    except ValueError:
        pass

    print("\n" + "=" * 60)
    if not flags:
        print("VERDICT: Looks legitimate — sender, path, and authentication are consistent.")
    else:
        print("VERDICT: SUSPICIOUS — this message shows signs of spoofing/phishing/spam:")
        for f in flags:
            print(f"  [!] {f}")

if __name__ == "__main__":
    sys.exit(main())
