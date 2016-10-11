#!/bin/bash

# DESCRIPTION: SCRIPT TO INSTALL ORACLE JAVA JDK 1.8.0_102
# HOW TO USE: RUN AS ROOT 
# AUTHOR: JEFFREY REEVES

# GLOBAL VARIABLES

unset JAVA_RPM_URL
unset JAVA_RPM_NAME
unset JAVA_VERSION

#JAVA_RPM_URL="http://download.oracle.com/otn-pub/java/jdk/8u102-b14/jdk-8u102-linux-x64.rpm"
#JAVA_RPM_NAME="jdk-8u102-linux-x64.rpm"
#JAVA_VERSION="1.8.0_102"

CONFIG=/etc/oracle-java.conf
[ -f $CONFIG ] && . $CONFIG

# MAIN

echo "This script will install Oracle Java JDK ${JAVA_VERSION}"
echo "Getting RPM file from Oracle..."

wget --no-check-certificate --no-cookies --header "Cookie: oraclelicense=accept-securebackup-cookie" ${JAVA_RPM_URL}
WGET_STATUS="$?"

# IF WGET SUCCEEDS
if [ ${WGET_STATUS} -eq "0" ]
then
	echo "RPM file ${JAVA_RPM_NAME} successfully downloaded"
	echo "Starting installation of RPM package..."

	rpm -ivh ${JAVA_RPM_NAME}
	RPM_INSTALL_STATUS="$?"

	if [ ${RPM_INSTALL_STATUS} -eq "0" ]
	then
		echo "RPM package successfully installed"
		echo "Checking Java Version..."

		java -version

		echo "Installation complete"
	else 
		echo "RPM package FAILED to be installed. Check the script and ensure the RPM name is correct."
	fi
else
	echo "Unable to download RPM file from Oracle. Check the script and ensure the URL is correct."
fi
