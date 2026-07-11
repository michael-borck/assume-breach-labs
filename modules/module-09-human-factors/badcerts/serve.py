#!/usr/bin/env python3
"""Serve three HTTPS sites, each with a deliberately broken TLS certificate, so
students see the real browser warnings. A self-contained, offline stand-in for
badssl.com. Certificates are minted fresh at start-up (so 'expired' is always
genuinely expired).

  https://localhost:8443  expired certificate
  https://localhost:8444  self-signed / untrusted certificate
  https://localhost:8445  certificate for the wrong hostname
"""
import datetime, ssl, threading, tempfile, os
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from cryptography import x509
from cryptography.x509.oid import NameOID
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import rsa

UTC = datetime.timezone.utc
now = datetime.datetime.now(UTC)
DAY = datetime.timedelta(days=1)

def make_pem(cn, not_before, not_after, san):
    key = rsa.generate_private_key(public_exponent=65537, key_size=2048)
    name = x509.Name([x509.NameAttribute(NameOID.COMMON_NAME, cn)])
    cert = (x509.CertificateBuilder()
            .subject_name(name).issuer_name(name)
            .public_key(key.public_key())
            .serial_number(x509.random_serial_number())
            .not_valid_before(not_before).not_valid_after(not_after)
            .add_extension(x509.SubjectAlternativeName([x509.DNSName(san)]), critical=False)
            .sign(key, hashes.SHA256()))
    path = tempfile.mktemp(suffix=".pem")
    with open(path, "wb") as f:
        f.write(key.private_bytes(serialization.Encoding.PEM,
                                  serialization.PrivateFormat.TraditionalOpenSSL,
                                  serialization.NoEncryption()))
        f.write(cert.public_bytes(serialization.Encoding.PEM))
    return path

SITES = [
    (8443, "Expired certificate",
     "This certificate expired 30 days ago. A real site with an expired "
     "certificate can no longer be trusted to be current.",
     make_pem("localhost", now - 400 * DAY, now - 30 * DAY, "localhost")),
    (8444, "Self-signed / untrusted certificate",
     "This certificate was signed by nobody your browser trusts (it signed "
     "itself). Anyone can make one of these — it proves nothing about identity.",
     make_pem("localhost", now - DAY, now + 365 * DAY, "localhost")),
    (8445, "Wrong hostname",
     "This certificate is valid, but it was issued for 'wrong.example.com', not "
     "for the site you actually visited. A certificate only vouches for the name "
     "it was issued to.",
     make_pem("wrong.example.com", now - DAY, now + 365 * DAY, "wrong.example.com")),
]

def page(title, explain):
    return f"""<!DOCTYPE html><html><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>{title}</title>
<style>body{{font-family:system-ui,sans-serif;max-width:40rem;margin:3rem auto;
padding:0 1rem;line-height:1.6;color:#14202e}}h1{{color:#b23b32}}
.box{{background:#f6f8fb;border:1px solid #dde3ec;border-radius:12px;padding:1.2rem}}</style>
</head><body>
<h1>&#9888; You reached the "{title}" site</h1>
<div class="box"><p><strong>If your browser showed a warning and you had to click
through to get here, it worked.</strong></p><p>{explain}</p></div>
<p>Go back and read exactly what the warning said — that wording is the lesson.</p>
</body></html>"""

def make_handler(title, explain):
    body = page(title, explain).encode()
    class H(BaseHTTPRequestHandler):
        def do_GET(self):
            self.send_response(200)
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)
        def log_message(self, *a):
            pass
    return H

def serve(port, title, explain, pem):
    ctx = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
    ctx.load_cert_chain(pem)
    httpd = ThreadingHTTPServer(("0.0.0.0", port), make_handler(title, explain))
    httpd.socket = ctx.wrap_socket(httpd.socket, server_side=True)
    print(f"  https://localhost:{port}  {title}", flush=True)
    httpd.serve_forever()

print("Broken-certificate test sites:", flush=True)
threads = [threading.Thread(target=serve, args=s, daemon=True) for s in SITES]
for t in threads:
    t.start()
for t in threads:
    t.join()
