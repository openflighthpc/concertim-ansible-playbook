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
      --extra-vars "memcache_host=concertim" \
      --tags prep,ganglia,metric-reporting \
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
# FROM scratch

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
    apt-get install --yes --no-install-recommends \
      gmetad \
      ruby3.0 && \
    apt-get clean && \
    rm -Rf /usr/share/doc && rm -Rf /usr/share/man && \
    rm -rf /var/lib/apt/lists/*

COPY --from=builder /etc/ganglia/gmetad.conf /etc/ganglia/gmetad.conf
COPY --from=builder /var/lib/gems/3.0.0/gems/ /var/lib/gems/3.0.0/gems/
COPY --from=builder /var/lib/gems/3.0.0/specifications/ /var/lib/gems/3.0.0/specifications/
COPY --from=builder /opt/concertim/opt/ct-metric-reporting-daemon /opt/concertim/opt/ct-metric-reporting-daemon 
COPY --from=builder /opt/concertim/opt/ct-metric-processing-daemon /opt/concertim/opt/ct-metric-processing-daemon 


COPY ./docker/metrics/entrypoint.sh /docker-entrypoint.sh
ENTRYPOINT ["/docker-entrypoint.sh"]
