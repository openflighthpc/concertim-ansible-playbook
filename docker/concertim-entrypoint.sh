#!/bin/bash

# This script is a total hack around a problem that shouldn't exist.  The
# problem should be fixed and this script removed. The problem:
#
# FSR the concertim container has a PID file for the Rails app which stops the
# server from starting.  This might be because the image is built with it or
# because its created when a container is started to run the database
# migrations.  Either way it needs to be removed.
#
# The correct fix would be to have a container that 1) doesn't run multiple
# services; 2) doesn't need an init system; and 3) doesn't use PID files.
#
# Another good fix would be discovering when the PID file is created and
# removing it then.

# This PID can get left behind in some circumstances.  For now we simply remove
# it, later we will look at how to avoid this situation.
if [ -f /opt/concertim/opt/ct-visualisation-app/core/tmp/pids/server.pid ] ; then
  rm /opt/concertim/opt/ct-visualisation-app/core/tmp/pids/server.pid
fi

if [ $# -gt 0 ] ; then
  exec "$@"
else
  exec /lib/systemd/systemd
fi
