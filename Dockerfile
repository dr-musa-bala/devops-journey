# TEMPORARY TEST: Outdated base image with known CVEs
FROM nginx:1.14.0

COPY index.html /usr/share/nginx/html/index.html
EXPOSE 80