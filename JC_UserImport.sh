#!/bin/bash

#########################################################################################
#
# JC_UserImport.sh - imports Linux users into JumpCloud(tm)
#
# This script provides two main benefits:
#
# 1. To help you identify existing users on your servers to either remove or add to
#   JumpCloud
#
# 2. To allow you to automatically add users to JumpCloud via a text list when they're
#   found on any server.
#
# NOTE: This script MUST be run as 'root'
#
# If you have any questions or problems with the operation of this script, please
# contact support@jumpcloud.com.
#
# License: This script is made available by JumpCloud under the
#   Mozilla Public License v2.0 (https://www.mozilla.org/MPL/2.0/)
#
# Author: James D. Brown (james@jumpcloud.com)
# Created: Mon, Apr 7, 2014
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

#
# Define your user emails here:
#
# They should be of the form:
#
# LinuxLoginName:Email
#
# One per line.
#
# When these accounts are found, if they are not yet set up as a JumpCloud managed user,
# they will be added to JumpCloud.
#
# NOTE: Root cannot be added as a JumpCloud user at this time. Doing so will create a
#   new user entry in /etc/passwd and /etc/shadow named 'root', but with a non-zero UID.
#
userAddEmailMap() {
    cat <<-EOF
demouser:demouser_example@mycompany.com
EOF
}

#
# Define all user accounts to ignore here. This should include any user logins that you
# do not wish JumpCloud to manage. Entries in this list are overridden by entries in the
# userAddEmailMap.
#
# They should be of the form:
#
# LinuxLoginName
#
# One per line.
#
userIgnoreList() {
    cat <<-EOF
guest
EOF
}


#
# Script code to follow should require no user modification.
#
shadowFile="/etc/shadow"

#
# This includes the names of default users created by installer packages. It is pre-pended
# to the userIgnoreList, and generally should change only with new package or distro
# updates. Entries in this list are overridden by entries in the userAddEmailMap.
#
defaultIgnoreList() {
    cat <<-EOF
root
bin
daemon
adm
lp
sync
shutdown
halt
mail
uucp
operator
games
gopher
ftp
nobody
dbus
usbmuxd
vcsa
rpc
rtkit
nscd
avahi-autoipd
abrt
rpcuser
nfsnobody
apache
ntp
saslauth
postfix
mysql
hsqldb
haldaemon
pulse
gdm
sshd
nslcd
tcpdump
mailnull
smmsp
sys
man
news
proxy
www-data
backup
list
irc
gnats
libuuid
syslog
messagebus
whoopsie
landscape
ubuntu
EOF
}

joinIgnoreLists() {
    userIgnoreList
    defaultIgnoreList
}

getMatchRegex() {
    firstDone=0;

    userAddEmailMap | while read line
    do
        login=`echo ${line} | awk -F':' '{ print $1; }'`

        if [ ${firstDone} -eq 1 ]
        then
            echo -n "|"
        fi

        echo -n "^${login}$"

        firstDone=1
    done
}

runningAsRoot() {
    if [ `id -u` -eq 0 ]
    then
        return 0
    else
        echo "This script must be run as root. EXITING."

        return 1
    fi
}

#
# Get the list of all shadow file lines that have an email associated with them
#
getAllAddUserAccounts() {
    matchList=`getMatchRegex | tr -d "^$"`

    grep -E "^(${matchList}):" ${shadowFile}
}

#
# Get the list of all user accounts without an email mapping, and which are ignored
#
getAllMissedUserAccounts() {
    matchList=`getMatchRegex | tr -d "^$"`

    grep -Ev "^${matchList}:" ${shadowFile} | while read line
    do
        login=`echo ${line} | awk -F':' '{ print $1; }' -`

        if [ `joinIgnoreLists | grep -c "${login}"` -eq 0 ]
        then
            #
            # Does the user not exist in JumpCloud already?
            #
            if [ `findAccountInJumpCloud "${login}" | grep -c "\"totalCount\":1"` -eq 0 ]
            then
                echo -n " ${login}"
            fi
        fi
    done
}

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

    email=`userAddEmailMap | grep "^${login}:" | awk -F':' '{ print $2; }' -`

    result=`curl --silent \
        -d "{\"email\" : \"${email}\", \"username\" : \"${login}\" }" \
        -X 'POST' \
        -H 'Content-Type: application/json' \
        -H 'Accept: application/json' \
        -H "x-api-key: ${jumpCloudAPIKey}" \
        "https://console.jumpcloud.com/api/systemusers"`

    if [ `echo "${result}" | grep -c '"status"'` -eq 1 ]
    then
        echo ""
        echo ""
        echo "ERROR: ${result}"
    else
        echo "SUCCESS"
    fi
}

runningAsRoot || exit 1

APIKeyIsValid

if [ ${?} -eq 1 ]
then
    echo "ERROR: The API key is unauthorized."
    exit 1
fi

#
# Do we have any users we don't know what to do with?
#
missed=`getAllMissedUserAccounts`

if [ ! -z "${missed}" ]
then
    echo "Unknown users (not in JumpCloud, userAddEmailMap, nor userIgnoreList):"
    echo ""
    echo "       ${missed}"
    echo ""
    echo "Please add these users to one of the above locations, and re-run JCUserImport.sh"
    echo ""
    echo "Exiting with return code 1"
    exit 1
fi

addUsers=`getAllAddUserAccounts`

for user in ${addUsers}
do
    login=`echo "${user}" | awk -F':' '{ print $1; }' -`

    #
    # Is the user account NOT already in JumpCloud?
    #
    if [ `findAccountInJumpCloud "${login}" | grep -c "\"totalCount\":1"` -eq 0 ]
    then

        echo -n "${login}: Adding to JumpCloud: "

        #
        # Not there, let's add it
        #
        addAccountToJumpCloud "${login}"
    else
        echo "${login}: Already exists in JumpCloud"
    fi
done

exit 0