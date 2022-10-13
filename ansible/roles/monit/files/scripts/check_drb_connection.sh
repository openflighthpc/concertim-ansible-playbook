#!/bin/bash
########################################################################################
# checks the daemon romance log file for daemon error messages and stops process if seen to be hung
# it assumes that the daemon is the 2nd arg of this script separated by "_", this way it can be used by many check scripts
# problem is monit does not allow args to be passed to scripts, so single script check_drb_connection.sh and many sym links.

# It also assumes that when it writes into romance.none.log this is a failure.....
# hacor - file exists with timestamp at startup
# sas - file does not exist at startup but when it fails lets just leave an empty file like hacor

daemon=$(echo $0 | cut -d_ -f2)
log=/opt/concurrent-thinking/${daemon}/log/romance.none.log

# Monit runs send new check, check previous check, execute check actions
# what it should do is
# check previous check, execute check actions, timeout, send new check

# sleep so that the program has time to restart before check runs again and gets a status back 
# to monit again
# monit checks every 60+runtime secs so as long as the script returns before the next execution and 
# gives time for the restart action, all works perfectly
# also, it may take mia nearly 20 seconds to see hacor's published models again

sleep 20 

if [ -f ${log} ]; then
   string="Multicasting presence message 'BYE PRODUCER ${daemon}'"
   grep "${string}" ${log} > /dev/null
   if [ $? = 0 ]; then
      echo "${daemon} found to be in DRB connection error state"
      #14162, this is now done in /usr/bin/mongrel_rails: cp /dev/null ${log} 
      exit 1
   fi
fi

# check with MIA that our service is still publishing its models
# use 404 to distinguish between an error and MIA just not being up
wget -SO- -T 5 -t 1 --no-check-certificate https://localhost/monit/service/${daemon} 2>&1 | grep "ERROR 404"
if [ $? = 0 ]; then
   echo "${daemon} not publishing its models in MIA"
   exit 1
fi

exit 0

# eof
