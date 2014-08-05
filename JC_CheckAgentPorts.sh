#!/bin/bash

#########################################################################################
#
# JC_CheckAgentPorts.sh - Verifies that all the necessary agent ports are open, to help
# 	diagnose potential installation or connectivity problems.
#
# If you have any questions or problems with the operation of this script, please
# contact support@jumpcloud.com.
#
# License: This script is made available by JumpCloud under the
#   Mozilla Public License v2.0 (https://www.mozilla.org/MPL/2.0/)
#
# Author: James D. Brown (james@jumpcloud.com)
# Created: Tue, Aug 5, 2014
#
# Copyright (c) 2014 JumpCloud, Inc.
#
#########################################################################################

servers="agent.jumpcloud.com kickstart.jumpcloud.com"
ports="443 444"

#
# Set the pathes of the following commands as appropriate for your server
#
CURL="/usr/bin/curl"
NSLOOKUP="/usr/bin/nslookup"

getIpList() {
	hostname=$1
	
	${NSLOOKUP} ${hostname} | awk '{
		if ($0 == "Non-authoritative answer:") {
			inAnswer=1;
		}

		if (inAnswer == 1 && $1 == "Address:") {
			print $2;
		}
	}' -
}

for file in ${CURL} ${NSLOOKUP}
do
	if [ ! -x "${file}" ]
	then
		echo "Path is not set correctly for ${file}, please correct and re-run"

		exit 1
	fi
done

echo "JumpCloud Agent Connection Verification Utility"
echo "-----------------------------------------------"

for name in ${servers}
do
	ipList=`getIpList ${name}`

	if [ -z "${ipList}" ]
	then
		echo "ERROR: Could not resolve IPs for ${name}"
		echo ""
		echo "Results:"
		${NSLOOKUP} ${name}
	fi

	for ip in ${ipList}
	do
		for port in ${ports}
		do
			echo -n "${name} (${ip}):${port}: "
	
			${CURL} --connect-timeout 3 https://${ip}:${port} 1>/dev/null 2>&1 
	
			err=$?
	
			#
			# No connect or connect timeout?
			#
			if [[ ${err} -eq 7 || ${err} -eq 28 ]]
			then
				echo "FAIL (err=${err})"
			else
				echo "OK"
			fi
		done
	done
done

exit 0
