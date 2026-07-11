# Serves three HTTPS sites with deliberately broken certificates (a self-hosted
# badssl.com). Certs are minted at start-up so 'expired' is always expired.
FROM python:3.12-slim
RUN pip install --no-cache-dir cryptography
COPY serve.py /serve.py
EXPOSE 8443 8444 8445
CMD ["python3", "/serve.py"]
