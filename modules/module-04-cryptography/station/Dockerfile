# Cryptography workstation for Module 04. Built on the shared base image (which
# has GnuPG and OpenSSL). Baked-in data: the classic-cipher tool, a ciphertext
# challenge, and the PGP keygen helper (~a few KB; no bind mounts).
FROM ghcr.io/michael-borck/assume-breach-base:latest

USER root
COPY --chown=analyst:analyst data /home/analyst/lab
RUN chmod +x /home/analyst/lab/cipher.py /home/analyst/lab/make-keys.sh \
    && ln -s /home/analyst/lab/cipher.py /usr/local/bin/cipher \
    && chown -R analyst:analyst /home/analyst

USER analyst
WORKDIR /home/analyst/lab
CMD ["sleep", "infinity"]
