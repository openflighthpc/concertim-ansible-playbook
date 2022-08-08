#!/bin/bash

ip address delete 192.168.56.3/255.255.255.0 dev enp0s8
ip address add 172.18.1.99/255.255.255.0 dev enp0s8
ip route add 172.18.1.0/255.255.255.0 dev enp0s8
