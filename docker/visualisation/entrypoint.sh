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

# Probably want to replace this with supervisor or something.

if [ $# -gt 0 ] ; then
  exec "$@"
else
  /usr/bin/memcached -v -m 256 -p 11211 -u memcache &

  /opt/concertim/opt/ct-visualisation-app/core/bin/rails server -p 7000 -b 0.0.0.0 -e production &

  export GOOD_JOB_WORKER=true
  cd /opt/concertim/opt/ct-visualisation-app/core
  /opt/concertim/opt/ct-visualisation-app/core/bin/bundle exec good_job start &

  # Wait for any process to exit.
  wait -n

  # Exit with the exit code of whichever process exited first.
  exit $?
fi
