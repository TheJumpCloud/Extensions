#!/bin/bash

#########################################################################################
#
# JC_RunCommandExample.sh - An example of running a command via the JumpCloud(tm)
#   runCommand API. This allows Command Runner users to execute commmands directly
#   via the API, since as of this writing, they cannot access the Triggers API.
#
# This script exports the commands saved and accessible by the API key provided, and
# lets you run a commmand by that user, as if it were executed by the "Run Now" button
# in the JumpCloud Commands tab.
#
# If you have any questions or problems with the operation of this script, please
# contact support@jumpcloud.com.
#
# License: This script is made available by JumpCloud under the
#   Mozilla Public License v2.0 (https://www.mozilla.org/MPL/2.0/)
#
# Author: James D. Brown (james@jumpcloud.com)
# Created: Mon, Jul 7, 2014
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

getCommands() {
    curl --silent \
        -X 'GET' \
        -H 'Content-Type: application/json' \
        -H 'Accept: application/json' \
        -H "x-api-key: ${jumpCloudAPIKey}" \
        "https://console.jumpcloud.com/api/commands"
}

getCommandById() {
    id="${1}"

    curl --silent \
        -X 'GET' \
        -H 'Content-Type: application/json' \
        -H 'Accept: application/json' \
        -H "x-api-key: ${jumpCloudAPIKey}" \
        "https://console.jumpcloud.com/api/commands/${id}"
}

showCommands() {

    #
    # Warning: For example purposes only, a comma within a field value, like a command name
    # or command string will break this...
    #
    # This excludes the complexity of adding a bashful JSON parser, but that's relatively
    # easy to add instead...
    #
    awk -F',' '{
            for (i=1; i<=NF; i++) {
                print $i;
            }
        }' - | sed 's/"results":[[][{]"//g
            s/"//g
            s/^[{]//g
            s/\[}]$//g
            s/[}]//g
            s/[]]//g' | awk -F':' 'BEGIN { idx=1; }
            {
                if ($1 == "name") {
                    name[idx]=$2;
                } else if ($1 == "command") {
                    command[idx]=$2;
                } else if ($1 == "_id") {
                    id[idx++]=$2;
                }
            }
            END {
                printf("%-26s\t%-20s\t%-40s\n", "ID", "Name", "Command");

                for(i=1; i<idx; i++) {
                    printf("%-26s\t%-20s\t%-40s\n", id[i], name[i], command[i]);
                }
            }' -
}

runCommand() {
    id="${1}"

    cmd=`getCommandById "${id}"`

    curl --silent \
        -d "${cmd}" \
        -X 'POST' \
        -H 'Content-Type: application/json' \
        -H 'Accept: application/json' \
        -H "x-api-key: ${jumpCloudAPIKey}" \
        "https://console.jumpcloud.com/api/runCommand"
}

if [ $# -eq 1 ]
then
    if [ ${1} == "show" ]
    then
        getCommands | showCommands
    else
        runCommand "${1}"
    fi
else
    echo "Usage: $0 [show|<command-id-to-execute>]"
fi

exit 0