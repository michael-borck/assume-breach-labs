# Module 09 quiz — a self-contained security-awareness quiz served over nginx.
FROM nginx:alpine
COPY index.html /usr/share/nginx/html/index.html
# exFAT source files can be 0700; make the page world-readable for nginx.
RUN chmod 644 /usr/share/nginx/html/index.html
EXPOSE 80
