#!/bin/bash

# Probably want to replace this with supervisor or something.

if [ $# -gt 0 ] ; then
  exec "$@"
else
  if [ ! -f /opt/concertim/etc/metric-reporting-daemon.yml ] ; then
    # Move the config file to a volume, so it can be edited if we wish.
    cp /opt/concertim/opt/ct-metric-reporting-daemon/config/config.yml \
      /opt/concertim/etc/metric-reporting-daemon.yml
  fi

  /usr/sbin/gmetad -c /etc/ganglia/gmetad.conf
  /opt/concertim/opt/ct-metric-reporting-daemon/ct-metric-reporting-daemon \
    --config-file /opt/concertim/etc/metric-reporting-daemon.yml &

  # Wait for any process to exit.
  wait -n

  # Exit with the exit code of whichever process exited first.
  exit $?
fi
