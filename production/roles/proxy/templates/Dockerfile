FROM nginx:latest

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
    && apt-get install --yes --no-install-recommends \
                php8.2-fpm \
    && apt-get clean \
    && rm -rf /usr/share/doc /usr/share/man /var/lib/apt/lists/*

COPY nginx /etc/nginx/
COPY {{proxy.ssl.crt_host_path}} {{proxy.ssl.crt_container_path}}
COPY {{proxy.ssl.key_host_path}} {{proxy.ssl.key_container_path}}
