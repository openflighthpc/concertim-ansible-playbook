#!/bin/bash

# This script is just so that monit can restart 2 processes should a check fail
# gmetad-agg_check_rrd needs to restart gmetad-agg and martha

# Do not use monit to restart martha as you always get "Action failed -- Other action already in progress -- please try again later" due to using it within a monit comand

/usr/bin/systemctl ${1} martha
logger -t monit "martha is in state ${1}"
/usr/bin/systemctl ${1} gmetad-agg

# eof
