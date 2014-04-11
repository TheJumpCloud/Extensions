#!/bin/bash

#########################################################################################
#
# JC_CSVUserImport.sh - imports users from a CSV file into JumpCloud(tm)
#
# This script accepts a .csv file as an argument, in either of the following forms:
#
# 1. login,email
# 2. email
#
# and loads them as system users into JumpCloud. If #2, the user name portion of the
# email is used to create the account. As is normal for JumpCloud, any newly-added
# users will receive an email prompting them to set up their password, SSH public
# key, and Google Authenticator.
#
# If you have any questions or problems with the operation of this script, please
# contact support@jumpcloud.com.
#
# License: This script is made available by JumpCloud under the
#   Mozilla Public License v2.0 (https://www.mozilla.org/MPL/2.0/)
#
# Author: James D. Brown (james@jumpcloud.com)
# Created: Fri, Apr 11, 2014
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

sourceFiles="${*}"

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

findAccountInJumpCloud() {
    login="${1}"

    curl --silent \
        -d "{\"filter\": [{\"username\" : \"${login}\"}]}" \
        -X 'POST' \
        -H 'Content-Type: application/json' \
        -H 'Accept: application/json' \
        -H "x-api-key: ${jumpCloudAPIKey}" \
        "https://console.jumpcloud.com/api/search/systemusers"
}

addAccountToJumpCloud() {
    login="${1}"
    email="${2}"

    result=`curl --silent \
        -d "{\"email\" : \"${email}\", \"username\" : \"${login}\" }" \
        -X 'POST' \
        -H 'Content-Type: application/json' \
        -H 'Accept: application/json' \
        -H "x-api-key: ${jumpCloudAPIKey}" \
        "https://console.jumpcloud.com/api/systemusers"`

    if [ `echo "${result}" | grep -c '"status"'` -eq 1 ]
    then
        echo "${result}"
    fi
}

normalizeCSV() {
    files="${*}"

    cat ${files} | tr "\r" "\n" | gawk -F',' '{
        login="";
        email="";

        # Is this a heading line?
        if (NR == 1 && NF == 2 && $2 !~ /@/) {

            # Yep, looks like a header, skip it
            next;
        }

        # Remove any double-quotes
        gsub(/"/, "");

        if (NF == 1) {
            len=split($0, parts, /@/);

            if (len == 2) {
                login=parts[1];
                email=$0;
            }
        } else if (NF == 2) {
            login=$1;
            email=$2;
        }

        printf("%s,%s\n", login, email);
    }' -
}

APIKeyIsValid

if [ ${?} -eq 1 ]
then
    echo "ERROR: The API key is unauthorized."
    exit 1
fi

for file in ${sourceFiles}
do
    if [ ! -r "${file}" ]
    then
        echo "${file}: does not exist"

        continue;
    fi

    normalizeCSV "${file}" | while read line
    do
        login=`echo ${line} | awk -F',' '{ print $1; }' -`
        email=`echo ${line} | awk -F',' '{ print $2; }' -`

        #
        # Account already in JumpCloud?
        #
        if [ `findAccountInJumpCloud "${login}" | grep -c "\"totalCount\":1"` -eq 1 ]
        then
            echo "${login}: already exists in JumpCloud"
        else
            echo -n "Adding ${login} (${email}): "

            #
            # Nope, add it
            #
            result=`addAccountToJumpCloud "${login}" "${email}"`

            if [ ! -z "${result}" ]
            then
                echo "ERROR: ${result}"
            else
                echo "SUCCESS"
            fi
        fi
    done
done

exit 0