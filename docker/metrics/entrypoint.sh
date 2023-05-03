#!/bin/bash

# Probably want to replace this with supervisor or something.

if [ $# -gt 0 ] ; then
  exec "$@"
else
  /usr/sbin/gmetad -c /etc/ganglia/gmetad.conf
  /opt/concertim/opt/ct-metric-reporting-daemon/ct-metric-reporting-daemon &
  /opt/concertim/opt/ct-metric-processing-daemon/ct-metric-processing-daemon &

  # Wait for any process to exit.
  wait -n

  # Exit with the exit code of whichever process exited first.
  exit $?
fi
