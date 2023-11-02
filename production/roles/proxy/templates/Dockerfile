FROM nginx:latest

ARG BUILD_DATE
ARG BUILD_VERSION
ARG BUILD_REVISION

LABEL org.opencontainers.image.created=$BUILD_DATE
LABEL org.opencontainers.image.version=$BUILD_VERSION
LABEL org.opencontainers.image.revision=$BUILD_REVISION
LABEL org.opencontainers.image.title="Alces Concertim Proxy"

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
    && apt-get install --yes --no-install-recommends \
                php8.2-fpm \
    && apt-get clean \
    && rm -rf /usr/share/doc /usr/share/man /var/lib/apt/lists/*

COPY nginx /etc/nginx/
COPY {{proxy.ssl.crt_host_path}} {{proxy.ssl.crt_container_path}}
COPY {{proxy.ssl.key_host_path}} {{proxy.ssl.key_container_path}}
