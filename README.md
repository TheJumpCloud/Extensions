Extensions
==========

Contains function and feature extensions for JumpCloud, including automated user import, CSV import, and others.

The following scripts are designed to be run via JumpCloud, to make it easy to distribute them across servers, and get results into a central location:

JC_UserImport.sh - a bash script that allows you to automatically and quickly import all your existing Linux users into JumpCloud, eliminate user accounts that should no longer exist on servers, and get all your user accounts into a central repository for easy management going forward.

The following scripts are designed to be run from any Linux host:

JC_CSVUserImport.sh - a bash script that imports JumpCloud system user accounts from a CSV file. It accepts a file containing either login and email, or just email (in which case the login will be taken from the email user name).

JC_CommandTriggerExample.sh - an example script that shows how to call a JumpCloud Command via a webhook

JC_RunCommandExample.sh - an example script that show how to call a JumpCloud Command via the normal REST API, to allow Command Runner users to run commands via the API

JC_CheckAgentPorts.sh - a script that verifies outbound connectivity from a Linux host for proper agent installation and operation
