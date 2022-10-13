#!/bin/bash
########################################################################################

daemon=$(echo $0 | cut -d_ -f2)


# sleep so that the program has time to restart before check runs again and gets a status back 
# to monit again. Emma's delayed job process can take a while to come up, so giving it 
# 20 secs to get is act together before checking again. #23475

sleep 20


# check with MIA that our service is still publishing its models
# use 404 to distinguish between an error and MIA just not being up
wget -SO- -T 5 -t 1 --no-check-certificate https://localhost/monit/service/${daemon} 2>&1 | grep "ERROR 404" > /dev/null
if [ $? = 0 ]; then
   echo "${daemon} not publishing its models in MIA"
   exit 1
fi

exit 0

# eof
