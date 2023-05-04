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
      --extra-vars "db_host=db" \
      --tags prep,memcached,ct-visualisation-app \
      /ansible/build-playbook.yml && \
    apt-get remove --yes \
        ansible \
        software-properties-common && \
    apt-get autoremove --yes && \
    apt-get clean && \
    rm -Rf /usr/share/doc && rm -Rf /usr/share/man && \
    rm -rf /var/lib/apt/lists/*

COPY ./docker/visualisation/entrypoint.sh /docker-entrypoint.sh
ENTRYPOINT ["/docker-entrypoint.sh"]

################
# Stage: final
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
    apt-get install --yes --no-install-recommends \
      memcached \
      libpq5 \
      ruby3.0 \
      tzdata && \
    apt-get clean && \
    rm -Rf /usr/share/doc && rm -Rf /usr/share/man && \
    rm -rf /var/lib/apt/lists/*

COPY --from=builder /opt/concertim/opt /opt/concertim/opt
COPY --from=builder /etc/memcached.conf /etc/memcached.conf
COPY --from=builder /opt/concertim/etc /opt/concertim/etc

# Install gems. FSR copying them from builder doesn't seem to work.  Probably
# because I wasn't handling native extensions correctly.  Ideally the following
# line could be used instead.
#   COPY --from=builder /var/lib/gems /var/lib/gems
RUN apt-get update && \
    apt-get install --yes --no-install-recommends \
      autoconf \
      bison \
      build-essential \
      libpq-dev \
      ruby3.0-dev && \
    cd /opt/concertim/opt/ct-visualisation-app/core && \
    ./bin/bundle install && \
    apt-get remove --yes \
      autoconf \
      bison \
      build-essential \
      libpq-dev \
      ruby3.0-dev && \
    apt-get autoremove --yes && \
    apt-get clean && \
    rm -Rf /usr/share/doc && rm -Rf /usr/share/man && \
    rm -rf /var/lib/apt/lists/*


ENV RAILS_LOG_TO_STDOUT=true

COPY ./docker/visualisation/entrypoint.sh /docker-entrypoint.sh
ENTRYPOINT ["/docker-entrypoint.sh"]
