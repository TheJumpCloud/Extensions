#!/bin/bash

#########################################################################################
#
# JC_CommandTriggerExample.sh - An example demonstrating how to call a Command Trigger
#   on JumpCloud
#
# If you have any questions or problems with the operation of this script, please
# contact support@jumpcloud.com.
#
# License: This script is made available by JumpCloud under the
#   Mozilla Public License v2.0 (https://www.mozilla.org/MPL/2.0/)
#
# Author: James D. Brown (james@jumpcloud.com)
# Created: Mon, Apr 14, 2014
#
# Copyright (c) 2014 JumpCloud, Inc.
#
#########################################################################################

######
# -------------------------- START USER CUSTOMIZATION SECTION  --------------------------
######

#
# To obtain your API key, login to the JumpCloud console, and using your user account
# menu in the upper right corner of the screen, select "API Settings".
#
jumpCloudAPIKey="<CHANGE_TO_YOUR_JUMPCLOUD_API_KEY>"

######
# --------------------------- END USER CUSTOMIZATION SECTION  ---------------------------
######

triggerNames="${*}"

if [ "$#" -lt 1 ]
then
    echo "Usage: $0 <file1> [[<file2>] ... ]"
    exit 1
fi

APIKeyIsValid() {
    login="${1}"

    result=`curl --silent \
        -d "{\"filter\": [{\"username\" : \"${login}\"}]}" \
        -X 'GET' \
        -H 'Content-Type: application/json' \
        -H 'Accept: application/json' \
        -H "x-api-key: ${jumpCloudAPIKey}" \
        "https://console.jumpcloud.com/api/systemusers"`

    if [ "${result}" = "Unauthorized" ]
    then
        return 1
    fi

    return 0
}

callTriggerByName() {

    triggerName="${1}"

    curl --silent \
        -X 'POST' \
        -H "x-api-key: ${jumpCloudAPIKey}" \
        "https://console.jumpcloud.com/api/command/trigger/${triggerName}"
}

APIKeyIsValid

if [ ${?} -eq 1 ]
then
    echo "ERROR: The API key is unauthorized."
    exit 1
fi

for trigger in ${triggerNames}
do
    callTriggerByName "${trigger}"
done

exit 0
