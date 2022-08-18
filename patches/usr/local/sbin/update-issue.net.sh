#!/bin/bash

# add release metadata to /etc/issue.net
job=`cat /etc/concurrent-thinking/appliance/release.yml | grep "^job" | cut -f2- -d" "`
version=`cat /etc/concurrent-thinking/appliance/release.yml | grep "^version" | cut -f2- -d" "`
revision=`cat /etc/concurrent-thinking/appliance/release.yml | grep "^revision" | cut -f2- -d" "`

cat /etc/issue.net.header > /etc/issue.net

if [ -z "$job" -o "$job" = "NONE" ]; then
    dev=$([ -d /sys/class/net/eth0 ] && echo /sys/class/net/eth0 || ls -d /sys/class/net/en* | head -n 1)
    idx=$(printf %02d $(expr $(printf '%d' 0x`md5sum ${dev}/address | cut -c1-2`) % 20))
    mac=`cat ${dev}/address`
    echo -e "\nThis appliance [$mac/$idx] is unlicensed and is release $version [$revision]." | fold -w70 -s >> /etc/issue.net
else
    licensee=`cat /etc/concurrent-thinking/appliance/release.yml | grep "^client" | cut -f2- -d" "`
    echo -e "\nThis appliance is licensed to $licensee [$job] and is release $version [$revision]." | fold -w70 -s >> /etc/issue.net
fi
