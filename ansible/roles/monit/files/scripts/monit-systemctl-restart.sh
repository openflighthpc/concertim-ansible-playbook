#!/bin/bash

daemon="$1"

if /usr/bin/systemctl is-active "$1" ; then
    /usr/bin/systemctl restart "$1"
else
    /usr/bin/systemctl start "$1"
fi
