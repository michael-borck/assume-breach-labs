#!/usr/bin/env python3
"""Tiny cleartext login endpoint on :8080 (listens on all interfaces, so it's
reachable both directly and through the VPN tunnel)."""
from http.server import BaseHTTPRequestHandler, HTTPServer
class H(BaseHTTPRequestHandler):
    def do_POST(self):
        n = int(self.headers.get("Content-Length", 0))
        body = self.rfile.read(n).decode("utf-8", "replace")
        self.send_response(200); self.end_headers(); self.wfile.write(b"login received\n")
        print("login:", body, flush=True)
    def log_message(self, *a): pass
HTTPServer(("0.0.0.0", 8080), H).serve_forever()
