#!/bin/bash

DESTHOST=$1
DESTPORT=$2

nc $1 1234
nc $1 2341
nc $1 3412

sleep 1

nc -q2 $DESTHOST $DESTPORT

