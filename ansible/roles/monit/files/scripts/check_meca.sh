#!/bin/bash
########################################################################################
# checks the delia log file for meca error messages and stops process if seen to be hung
daemon=meca
log=/var/log/delia.log

# Monit runs send new check, check previous check, execute check actions
# what it should do is
# check previous check, execute check actions, timeout, send new check

# sleep so that the program has time to restart before check runs again and gets a status back 
# to monit again
# monit checks every 60 secs so as long as the script returns before the next execution and 
# gives time for the restart action, all works perfectly
sleep 15 

# Find what the port number is for the presently active daemon
# Must use both in the grep as you dont know which is the present live one

port=$(egrep "Found new producer ${daemon}|Producer ${daemon} moved" ${log}| tail -1 | cut -d: -f5 | cut -d" " -f7 2>/dev/null)
# If above did not work maybe the daemon moved port and the cut is slightly different
if [ -z "${port}" ]; then
   port=$(egrep "Found new producer ${daemon}|Producer ${daemon} moved" ${log}| tail -1 | cut -d: -f5 | cut -d" " -f6 2>/dev/null)
fi

# set up the broken connection error based on latest port
# You must get a port number or we cannot assertain if its recent or old

if [ -n "${port}" ]; then
   string="Message processing failed for: 'HELLO PRODUCER ${daemon} ${port}'"
   grep "${string}" ${log} > /dev/null
   err1=$?

   # set up the different broken connection error
   # check from match to end of file for either a started or moved to get right piece of data
   string1="Found new producer ${daemon} at ${port}"
   string2="Producer ${daemon} moved to ${port}"
   string3="Message processing failed for: 'BYE PRODUCER ${daemon}'"
   sed -n -e ' /'"${string1}"'/,/$/p' $log | grep "${string3}" > /dev/null
   err2=$?
   sed -n -e ' /'"${string2}"'/,/$/p' $log | grep "${string3}" > /dev/null
   err3=$?

   # If it matches then there is an error
   if [ ${err1} = 0 -o ${err2} = 0 -o ${err3} = 0 ]; then
      echo "Found to be in DRB connection error state"
      exit 1
   fi
fi

# This now done in check_drb_connection.sh, which is a common shared test script
# check with MIA that our service is still publishing its models
# use 404 to distinguish between an error and MIA just not being up
#wget -SO- -T 5 -t 1 --no-check-certificate https://localhost/monit/service/${daemon} 2>&1 | grep "ERROR 404"
#if [ $? = 0 ]; then
#   echo "${daemon} not publishing its models in MIA"
#   exit 1
#fi

# also check if the group update kicker is unable to access the group_id method of other models
log=/opt/concurrent-thinking/meca/log/group_update_kicker.log
fails=$(tail -5 ${log} | grep "undefined method \`group_ids'" | wc -l)
if [ ${fails} = 1 ]; then
  echo "Group update kicker unable to access external models"
  exit 1
fi

# #21957
# Also we have recently seen the same issue with meca as with hacor and have therefore implemented hacors drb checker
/usr/local/sbin/check_meca_connection.sh

exit 0

# eof
