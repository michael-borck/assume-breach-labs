# Digital-forensics workstation for Module 08. Two offline Python tools:
# mailtrace (email header analysis) and stylometry (authorship attribution).
# Replaces the old lab's online header tools and the Windows 'Signature' app.
FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
        python3 ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN useradd -m -s /bin/bash analyst
COPY --chown=analyst:analyst data /home/analyst/lab
RUN chmod +x /home/analyst/lab/mailtrace.py /home/analyst/lab/stylometry.py \
    && ln -s /home/analyst/lab/mailtrace.py /usr/local/bin/mailtrace \
    && ln -s /home/analyst/lab/stylometry.py /usr/local/bin/stylometry \
    && chown -R analyst:analyst /home/analyst

USER analyst
WORKDIR /home/analyst/lab
CMD ["sleep", "infinity"]
