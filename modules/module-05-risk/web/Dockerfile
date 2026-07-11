# Module 05 serves a single self-contained page (the risk calculator) over nginx.
# The page is baked in — fully offline, no external assets.
FROM nginx:alpine
COPY index.html /usr/share/nginx/html/index.html
# Ensure the file is world-readable: source files on an exFAT drive can carry
# 0700 perms, which nginx's worker (user 'nginx') then can't read (HTTP 403).
RUN chmod 644 /usr/share/nginx/html/index.html
EXPOSE 80
