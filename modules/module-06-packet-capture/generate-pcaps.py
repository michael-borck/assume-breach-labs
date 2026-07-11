#!/usr/bin/env python3
"""Generate the teaching capture files for Module 06 with scapy.

Produces six .pcap files students analyse in Wireshark:
  ftp-login.pcap     a cleartext FTP session — username + password in the clear
  telnet-login.pcap  a cleartext telnet login — one failed attempt, then success
  http-browse.pcap   a plain HTTP page fetch
  dns-query.pcap     a DNS lookup resolving a hostname to an IP
  icmp-ping.pcap     four ICMP echo request/reply pairs (a ping)
  port-scan.pcap     a TCP SYN scan (SYN -> SYN/ACK for open, RST/ACK for closed)

Run:  python3 generate-pcaps.py <output-dir>
"""
import sys
from scapy.all import (Ether, IP, TCP, UDP, ICMP, Raw,
                       DNS, DNSQR, DNSRR, wrpcap)

OUT = sys.argv[1] if len(sys.argv) > 1 else "."
CLI_MAC, SRV_MAC = "02:00:00:00:00:10", "02:00:00:00:00:20"


def stream(cli, sport, srv, dport, exchanges, t0=1000.0):
    """Build a realistic TCP conversation: handshake, then request/response
    payloads with correct seq/ack so Wireshark's Follow TCP Stream works."""
    pkts, t = [], t0
    cseq, sseq = 1000, 5000

    def c(flags, ack=0, load=None):
        p = Ether(src=CLI_MAC, dst=SRV_MAC)/IP(src=cli, dst=srv)/TCP(
            sport=sport, dport=dport, flags=flags, seq=cseq, ack=ack)
        if load is not None:
            p = p/Raw(load=load)
        return p

    def s(flags, ack=0, load=None):
        p = Ether(src=SRV_MAC, dst=CLI_MAC)/IP(src=srv, dst=cli)/TCP(
            sport=dport, dport=sport, flags=flags, seq=sseq, ack=ack)
        if load is not None:
            p = p/Raw(load=load)
        return p

    syn = c("S"); syn.time = t; t += 0.001; cseq += 1
    synack = s("SA", ack=cseq); synack.time = t; t += 0.001; sseq += 1
    ack = c("A", ack=sseq); ack.time = t; t += 0.01
    pkts += [syn, synack, ack]

    for who, data in exchanges:
        b = data.encode() if isinstance(data, str) else data
        if who == "c":
            p = c("PA", ack=sseq, load=b); p.time = t; t += 0.02; cseq += len(b)
            pkts.append(p)
            a = s("A", ack=cseq); a.time = t; t += 0.005; pkts.append(a)
        else:
            p = s("PA", ack=cseq, load=b); p.time = t; t += 0.02; sseq += len(b)
            pkts.append(p)
            a = c("A", ack=sseq); a.time = t; t += 0.005; pkts.append(a)
    return pkts


# 1) Cleartext FTP login — the credentials are visible in the packet bytes.
ftp = stream("10.6.0.10", 44011, "10.6.0.20", 21, [
    ("s", "220 LabFTP server ready\r\n"),
    ("c", "USER auditor\r\n"),
    ("s", "331 Password required for auditor\r\n"),
    ("c", "PASS Spr1ng2024!\r\n"),
    ("s", "230 Login successful\r\n"),
    ("c", "SYST\r\n"),
    ("s", "215 UNIX Type: L8\r\n"),
    ("c", "QUIT\r\n"),
    ("s", "221 Goodbye\r\n"),
])
wrpcap(f"{OUT}/ftp-login.pcap", ftp)

# 2) Cleartext telnet login — a failed attempt, then a successful one.
telnet = stream("10.6.0.10", 45012, "10.6.0.20", 23, [
    ("s", "\r\nUbuntu 20.04.6 LTS\r\nlabserver login: "),
    ("c", "admin\r\n"),
    ("s", "Password: "),
    ("c", "letmein\r\n"),
    ("s", "\r\nLogin incorrect\r\nlabserver login: "),
    ("c", "admin\r\n"),
    ("s", "Password: "),
    ("c", "Adm1n!2024\r\n"),
    ("s", "\r\nWelcome to labserver.\r\nadmin@labserver:~$ "),
    ("c", "whoami\r\n"),
    ("s", "admin\r\nadmin@labserver:~$ "),
    ("c", "exit\r\n"),
])
wrpcap(f"{OUT}/telnet-login.pcap", telnet)

# 3) Plain HTTP page fetch.
http = stream("10.6.0.10", 44022, "10.6.0.30", 80, [
    ("c", "GET /index.html HTTP/1.1\r\nHost: intranet.lab\r\n"
          "User-Agent: Mozilla/5.0\r\nAccept: text/html\r\n\r\n"),
    ("s", "HTTP/1.1 200 OK\r\nServer: nginx\r\nContent-Type: text/html\r\n"
          "Content-Length: 46\r\n\r\n<html><body><h1>Intranet Home</h1></body></html>"),
])
wrpcap(f"{OUT}/http-browse.pcap", http)

# 4) DNS lookup — client asks the resolver for www.intranet.lab, gets an A record.
DNS_MAC = "02:00:00:00:00:53"
dq = (Ether(src=CLI_MAC, dst=DNS_MAC)/IP(src="10.6.0.10", dst="10.6.0.53")/
      UDP(sport=51000, dport=53)/DNS(id=0x1a2b, rd=1,
      qd=DNSQR(qname="www.intranet.lab", qtype="A")))
dq.time = 1500.0
dr = (Ether(src=DNS_MAC, dst=CLI_MAC)/IP(src="10.6.0.53", dst="10.6.0.10")/
      UDP(sport=53, dport=51000)/DNS(id=0x1a2b, qr=1, aa=1, rd=1, ra=1,
      qd=DNSQR(qname="www.intranet.lab", qtype="A"),
      an=DNSRR(rrname="www.intranet.lab", type="A", ttl=300, rdata="10.6.0.30")))
dr.time = 1500.03
wrpcap(f"{OUT}/dns-query.pcap", [dq, dr])

# 5) ICMP ping — four echo request/reply pairs.
ping, t = [], 1600.0
for i in range(4):
    payload = b"abcdefghijklmnopqrstuvwabcdefghi"
    req = (Ether(src=CLI_MAC, dst=SRV_MAC)/IP(src="10.6.0.10", dst="10.6.0.20")/
           ICMP(type=8, id=0x4242, seq=i)/Raw(load=payload))
    req.time = t; t += 0.01
    rep = (Ether(src=SRV_MAC, dst=CLI_MAC)/IP(src="10.6.0.20", dst="10.6.0.10")/
           ICMP(type=0, id=0x4242, seq=i)/Raw(load=payload))
    rep.time = t; t += 0.99
    ping += [req, rep]
wrpcap(f"{OUT}/icmp-ping.pcap", ping)

# 6) TCP SYN scan: SYN to many ports; SYN/ACK from open ports, RST/ACK from closed.
scan, t = [], 2000.0
open_ports = {22, 80}
for i, port in enumerate([21, 22, 23, 25, 53, 80, 110, 143, 443, 3306, 8080, 9000]):
    syn = Ether(src=CLI_MAC, dst=SRV_MAC)/IP(src="10.6.0.10", dst="10.6.0.20")/TCP(
        sport=40000+i, dport=port, flags="S", seq=1000+i)
    syn.time = t; t += 0.004; scan.append(syn)
    flags = "SA" if port in open_ports else "RA"
    rsp = Ether(src=SRV_MAC, dst=CLI_MAC)/IP(src="10.6.0.20", dst="10.6.0.10")/TCP(
        sport=port, dport=40000+i, flags=flags, seq=7000+i, ack=1001+i)
    rsp.time = t; t += 0.004; scan.append(rsp)
wrpcap(f"{OUT}/port-scan.pcap", scan)

print("wrote ftp-login.pcap, http-browse.pcap, port-scan.pcap to", OUT)
