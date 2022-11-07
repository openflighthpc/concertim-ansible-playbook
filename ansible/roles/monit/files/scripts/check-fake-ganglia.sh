#!/bin/bash

# The number of unchanged reads required for us to consider the fake ganglia server to have failed.
MIN_READS=3

OUT_FILE=/tmp/check-fake-ganglia.out
XPATH="GANGLIA_XML/GRID/CLUSTER/HOST[@NAME='comp001.concertim.alces-flight.com']/METRIC[@NAME='ct.snmp.load.1']/@VAL"
VAL=$(nc -d localhost 8651 | xmlstarlet select --template  -v "${XPATH}")

echo "${VAL}" >> "${OUT_FILE}"

NUM_READS=$( cat "${OUT_FILE}" \
	| sed '/^ *$/d' \
	| wc -l )

# If we haven't recorded 3 values yet, we're all good.
if [ $NUM_READS -lt ${MIN_READS} ] ; then
	exit 0
fi

# If the last MIN_READS values are all the same, we're not good.
UNIQ_VALS=$( cat "${OUT_FILE}" \
	| sed '/^ *$/d' \
	| tail -n ${MIN_READS} \
	| sort -u \
	| wc -l )

if [ "${UNIQ_VALS}" == "1" ] ; then
	# The last 3 values have all been the same.  This sounds wrong.
	rm "${OUT_FILE}"
	exit 1
else
	exit 0
fi
