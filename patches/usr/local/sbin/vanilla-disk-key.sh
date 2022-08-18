#!/bin/bash
dev=$([ -d /sys/class/net/eth0 ] && echo /sys/class/net/eth0 || ls -d /sys/class/net/en* | head -n 1)
idx=$(printf %02d $(expr $(printf '%d' 0x`md5sum ${dev}/address | cut -c1-2`) % 20))
echo /data/private/share/vanilla/$idx.key
