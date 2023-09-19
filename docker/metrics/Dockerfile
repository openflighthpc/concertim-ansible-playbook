################
# Stage: builder
FROM ubuntu:22.04 as builder
LABEL com.alces-flight.concertim.role=builder

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

ADD ./ansible/ /ansible
# Add secrets used for downloading our pre-packaged software from AWS.
ADD ./docker/secrets/vault-password.txt /run/secrets/
ADD ./docker/secrets/aws-credentials.yml.enc /run/secrets/

RUN apt-get update && \
    ansible-playbook \
      --inventory /ansible/inventory.ini \
      --vault-password-file /run/secrets/vault-password.txt \
      --extra-vars "@/run/secrets/aws-credentials.yml.enc" \
      --extra-vars "docker_build=true" \
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
LABEL com.alces-flight.concertim.role=metrics com.alces-flight.concertim.version=0.1.3

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
    apt-get install --yes --no-install-recommends \
      gmetad && \
    apt-get clean && \
    rm -Rf /usr/share/doc && rm -Rf /usr/share/man && \
    rm -rf /var/lib/apt/lists/*

COPY --from=builder /etc/ganglia/gmetad.conf /etc/ganglia/gmetad.conf
COPY --from=builder /opt/concertim/opt/ct-metric-reporting-daemon /opt/concertim/opt/ct-metric-reporting-daemon 

COPY ./docker/metrics/entrypoint.sh /docker-entrypoint.sh
ENTRYPOINT ["/docker-entrypoint.sh"]
