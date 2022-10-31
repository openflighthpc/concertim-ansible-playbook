#!/bin/bash

# What is this script for:
# 1. Check to see what rrd have been modified (-mmin) in the last ${rrd_age} mins
# 2. Check the timestamp on the rrdupdate is less than ${rrd_age} mins
# 3. If not, assume that gmetad is not updating rrd files and may have locked up

rrd_age=10 # check if rrds not been updated for this many minutes

# So we can use this for multiple gmetad's then grab the name of the daemon
# from the symlinked filename
daemon=$(echo $0 | cut -d_ -f2)
if [ "${daemon}" = "gmetad" ]; then
   location=unspecified
elif [ "${daemon}" = "gmetad-agg" ]; then
   location=groups
else
   echo "Location not defined for this gmetad daemon ${daemon}"
   exit
fi

# Define where the rrds are located
rrd_location=/var/lib/ganglia/rrds/${location}

# Add a sleep to prevent false negative when the daemon is being restarted.
# This combined with requiring a negative result for 2 cycles should be
# sufficient to prevent a restarting daemon from being incorrectly detected as
# non-functional.
sleep 15 

# Get an rrd file which has been accessed in the last ${rrd_age} mins, which
# is not a derived metric, capacity metric or comes from any strange
# appliance.local device
rrd_file=$(find ${rrd_location} -type f -iname "*rrd" -mmin -${rrd_age} | egrep -v "appliance.local|ct.capacity|ct.calc|user.calc" | sort -M | tail -1)


if [ -n "${rrd_file}"  ]; then
   # Get the time of this rrd file lastupdate time in julian
   rrd_time=$(rrdtool lastupdate ${rrd_file} | tail -1 | awk -F: '{print $1}')

   # Add ${rrd_age} mins, in secs to the lastupdate julian time, so we only
   # check if its older than $rrd_age} minutes
   (( rrd_time = rrd_time + 60 * rrd_age ))

   # Get the time now in julian
   the_time=$(date '+%s')

   # Now chck if the rrd file is stil less then real time even after you have
   # added ${rrd_age} mins (600 secs)
   if [ ${rrd_time} -lt ${the_time} ]; then
      echo "RRD files are too old, ${daemon} may have hung"
      # if it is too old, then exit 1 which will tell monit to restart the gmetad daemon ${daemon}.
      exit 1
   fi
else
   echo "No RRD files found newer than ${rrd_age} mins for ${daemon}"
   # if it is too old, then exit 1 which will tell monit to restart the gmetad daemon ${daemon}.
   exit 1
fi

# eof
