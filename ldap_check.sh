#!/bin/bash

###############################################################################
#
# ldap_check.sh - Reads in LDAP Binding User Service Account, organization ID
#       and service account password to aid in troubleshooting ldap
#       connectivity problems.
#
# Questions or issues with the operation of the script, please contact
# support@jumpcloud.com
#
# Author: Rob Holden | rholden@jumpcloud.com
# 
###############################################################################

clear

#
# Help screen
#

help() {

echo "###################################################################"
echo "#                                                                 #"
echo "#          LDAP setup and troubleshooting utility                 #"
echo "#                                                                 #"
echo "###################################################################"
echo ""
echo "Enter q to exit"
echo ""
echo "This utility is meant to assist in testing and configuring LDAP	"
echo "with JumpCloud using the native ldapsearch command.            	"
echo ""
echo "Step 1. Enter account variables					"
echo "	LDAP Binding User account name:  If you do not know this, please"
echo "	refer to http://support.jumpcloud.com/knowledgebase/articles/474"
echo "	035-configuring-your-application-with-jumpcloud-ldap		"
echo ""
echo "	Password:  This is the password for the LDAP Binding User	"
echo ""
echo "	Organization ID: if you do not know this, please refer to http:/"
echo "	/support.jumpcloud.com/knowledgebase/articles/413926-jumpcloud-s-"
echo "	hosted-ldap-service						"
echo ""
echo "Step 2. Pick a port using option 2 or 3				"
echo ""
echo "Step 3. Option 4 will allow you to connect to LDAP and search  	"
echo "using the defined account variables				"
echo ""
echo "Option 5 will list common strings used by the applications	"
echo "that will athenticate to JumpCloud LDAP.				"
echo ""
echo "Option 9 displays this help screen				"
echo ""
echo "Option 0 will exit the utility					"
}


#
# ldapsearch
#

# Check for ldapsearch command

ldapsearch=`which ldapsearch`

which ldapsearch &>/dev/null;

if [ $? != 0 ]
	then
		echo "ldapsearch is not in your path or not installed.  Please correct and rerun this script";
		exit 1;
fi


# Check account vars have been entered

check_ldap_config() {

if [ -z "$port" ]
        then
                echo "Port Undefined, using default 636";
                port=636;
                read -rsp $'press key to continue \n' -n1 key
fi

if [ "$port" = "389 -ZZ" ]
        then
                uri=ldap
        else
                uri=ldaps
fi

if [ -z "$user" ]
        then
                echo -e "\nAccount variables undefined, enter information and reselect\n";
                read_account;
fi
}

# Define ldapsearch 

ldsearch() {

check_ldap_config

$ldapsearch -H ${uri}://ldap.jumpcloud.com:${port} -x -b "ou=Users,o=${oid},dc=jumpcloud,dc=com" -D "uid=${user},ou=Users,o=${oid},dc=jumpcloud,dc=com" -w "${pass}" "(objectClass=${search_param})" | less

}

#
# Display common configuration strings
#

echo_ldap_config() {

echo "###################################################################"
echo "#                Common LDAP Configuration Settings               #"
echo "###################################################################"
echo ""
echo "### URI/LDAP Server ###"
echo ""
echo "ldaps://ldap.jumpcloud.com:636"
echo "ldap://ldap.jumpcloud.com:389"
echo ""
echo "### BIND DN ###"
echo ""
echo "uid=${user},ou=Users,o=${oid},dc=jumpcloud,dc=com"
echo ""
echo "### Search DN/Base Search DN ###"
echo ""
echo "ou=Users,o=${oid},dc=jumpcloud,dc=com"
echo ""
echo "### LDAP Search Example ###"
echo ""
echo "$ldapsearch -H ${uri}://ldap.jumpcloud.com:${port} -x -b \"ou=Users,o=${oid},dc=jumpcloud,dc=com\" -D \"uid=${user},ou=Users,o=${oid},dc=jumpcloud,dc=com\" -w \"${pass}\" \"(objectClass=inetOrgPerson)\""
echo ""
echo "**If the above ldapsearch command results in invalid credentials, and the password contains special characters (!,@,#,etc...), replace the double quotes (\") around the password with single quotes (') and retry"
echo ""
}

# Display the settings

ldap_config() {

check_ldap_config
echo_ldap_config | less

}

#
# read in oid, ldap service account and password
#

# read username, check for null input

read_user() {
echo -n "Enter LDAP Binding User account name: "
        read user;
if [ -z "$user" ]
        then
                echo "Input cannot be null"; read_user;
        else
                read_pass;
fi
}

# read password, check for null input

read_pass() {
echo -n "Enter password: "
        read -s pass;
echo
if [ -z "$pass" ]
        then
                echo "Input cannot be null"; read_pass;
        else
                read_oid;
fi
}

# read oid, check for null input

read_oid() {
echo -n "Enter the organization ID: "
        read oid;
if [ -z "$oid" ]
        then
                echo "Input cannot be null"; read_oid;
        else continue;
fi
}

read_account() {

read_user

read_pass

read_oid

}

#
# Define LDAP menu
#

ldap_menu() {

clear
echo "###### LDAP Search Options ######"
echo
echo "1. List Users";
echo "2. List POSIX Groups";
echo "3. List Groups of Names";
echo "0. Main Menu";

}

#
# Read LDAP menu
#

read_ldap_menu() {
echo -ne "\nSelect an option: "
        read ldap_option
        case $ldap_option in
                1) search_param=inetOrgPerson; ldsearch;;
                2) search_param=posixGroup; ldsearch;;
                3) search_param=grouOfNames; ldsearch;;
                0) break;;
                *) echo -e "\nNO OPTION ENTERED";;
        esac

}

#
# Launch LDAP search menu
#

ldap_search_menu() {

while true
do
        ldap_menu
        read_ldap_menu
done

}


#
# Define main menu
#

main_menu() {
echo "###########################";
echo "####    Main Menu     #####";
echo "###########################";
echo
echo "1. Enter account variables";
echo "2. Set LDAP port 389 (STARTTLS)";
echo "3. Set LDAP port 636 (SSL)";
echo "4. LDAP Search Menu";
echo "5. Display Common LDAP settings";
echo "9. Help";
echo "0. Exit";

}

#
# Read main menu options
#

read_main_menu() {
echo -ne "\nSelect an option: "
        read option
        case $option in
                1) read_account;;
                2) port="389 -ZZ"; echo -e "\n**Port set to 389\n";;
                3) port=636; echo -e "\n**Port set to 636\n";;
                4) ldap_search_menu;;
                5) ldap_config;;
                9) help | less;;
                0) exit 0;;
                *) echo -e "\nNO OPTION ENTERED";;
        esac
}

#
# Launch main menu
#

while true
do
        main_menu
        read_main_menu
done

