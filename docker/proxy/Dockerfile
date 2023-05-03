################
# Stage: builder
FROM ubuntu:22.04 as builder

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
      && apt-get install --yes --no-install-recommends \
          gpg-agent \
          software-properties-common \
          git \
          sudo \
      && add-apt-repository --yes ppa:ansible/ansible \
      && apt-get install --yes --no-install-recommends \
          ansible \
      && apt-get clean \
      && rm -Rf /usr/share/doc && rm -Rf /usr/share/man \
      && rm -rf /var/lib/apt/lists/*

ADD ./ansible/ /ansible

RUN apt-get update && \
    ansible-playbook \
      --inventory /ansible/inventory.ini \
      --extra-vars "docker_build=true" \
      --extra-vars "visualisation_host=concertim metrics_host=metrics" \
      --tags webserver \
      /ansible/build-playbook.yml && \
    apt-get remove --yes \
        ansible \
        software-properties-common && \
    apt-get autoremove --yes && \
    apt-get clean && \
    rm -Rf /usr/share/doc && rm -Rf /usr/share/man && \
    rm -rf /var/lib/apt/lists/*

################
# Stage: final
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
    apt-get install --yes --no-install-recommends \
      ssl-cert \
      nginx \
      php8.1-fpm && \
    apt-get clean && \
    rm -Rf /usr/share/doc && rm -Rf /usr/share/man && \
    rm -rf /var/lib/apt/lists/* && \
# remove the default site shipped with package, we use the site copied below.
    rm /etc/nginx/sites-enabled/default && \
# forward request and error logs to docker log collector
    ln -sf /dev/stdout /var/log/nginx/access.log && \
    ln -sf /dev/stderr /var/log/nginx/error.log

COPY --from=builder /etc/nginx /etc/nginx

CMD ["nginx", "-g", "daemon off;"]
