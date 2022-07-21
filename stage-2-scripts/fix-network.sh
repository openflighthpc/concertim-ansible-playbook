#!/bin/bash

ip address delete 192.168.56.3/255.255.255.0 dev enp0s8
ip address add 172.18.1.99/255.255.255.0 dev enp0s8
route add -net 172.18.1.0 netmask 255.255.255.0 enp0s8
