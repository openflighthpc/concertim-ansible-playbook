FROM eniocarboni/docker-ubuntu-systemd:22.04

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
      && apt-get install --yes --no-install-recommends \
          gpg-agent \
          software-properties-common \
          git \
          sudo \
          postgresql-client-14 \
      && add-apt-repository --yes ppa:ansible/ansible \
      && apt-get install --yes --no-install-recommends \
          ansible \
      && apt-get clean \
      && rm -Rf /usr/share/doc && rm -Rf /usr/share/man \
      && rm -rf /var/lib/apt/lists/*

# Used for downloading our pre-packaged software from AWS.
ARG AWS_ACCESS_KEY_ID
ARG AWS_SECRET_ACCESS_KEY

ADD ./ansible/ /ansible

RUN apt-get update && \
    ansible-playbook \
      --inventory /ansible/inventory.ini \
      --extra-vars "aws_access_key_id=$AWS_ACCESS_KEY_ID aws_secret_access_key=$AWS_SECRET_ACCESS_KEY" \
      --extra-vars "docker_build=true" \
      /ansible/build-playbook.yml && \
    apt-get remove --yes \
        ansible \
        git \
        gpg-agent \
        software-properties-common && \
    apt-get autoremove --yes && \
    apt-get clean && \
    rm -Rf /usr/share/doc && rm -Rf /usr/share/man && \
    rm -rf /var/lib/apt/lists/*
      # /ansible/build-playbook.yml

COPY ./docker/concertim-entrypoint.sh /docker-entrypoint.sh
ENTRYPOINT ["/docker-entrypoint.sh"]
