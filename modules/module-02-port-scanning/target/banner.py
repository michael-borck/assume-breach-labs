#!/usr/bin/env python3
"""A tiny 'mystery service' that greets any connection with a version banner.
Gives nmap -sV something to fingerprint on an otherwise unknown port."""
import socket, sys

port = int(sys.argv[1]) if len(sys.argv) > 1 else 9000
text = sys.argv[2] if len(sys.argv) > 2 else "Custom-App 2.1"

srv = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
srv.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
srv.bind(("0.0.0.0", port))
srv.listen(8)
while True:
    try:
        conn, _ = srv.accept()
        conn.sendall((text + "\r\n").encode())
        conn.close()
    except Exception:
        pass
