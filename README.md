Extensions
==========

Contains function and feature extensions for JumpCloud, including automated user import, CSV import, and others.

The following scripts are designed to be run via JumpCloud, to make it easy to distribute them across servers, and get results into a central location:

JC_UserImport.sh - a bash script that allows you to automatically and quickly import all your existing Linux users into JumpCloud, eliminate user accounts that should no longer exist on servers, and get all your user accounts into a central repository for easy management going forward.

The following scripts are designed to be run from any Linux host:

JC_CSVImport.sh - a bash script that imports JumpCloud system user accounts from a CSV file. It accepts a file containing either login and email, or just email (in which case the login will be taken from the email user name).
