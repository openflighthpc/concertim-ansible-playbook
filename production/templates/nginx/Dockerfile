FROM nginx:latest

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
    && apt-get install --yes --no-install-recommends \
                ssl-cert \
                php8.2-fpm \
    && apt-get clean \
    && rm -rf /usr/share/doc /usr/share/man /var/lib/apt/lists/*

COPY nginx /etc/nginx/
# COPY my-site.crt /etc/ssl/certs/my-site.crt
# COPY my-site.key /etc/ssl/private/my-site.key
