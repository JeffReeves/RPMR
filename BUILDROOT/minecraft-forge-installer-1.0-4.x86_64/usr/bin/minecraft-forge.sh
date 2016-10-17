#!/bin/bash

# DESCRIPTION: SCRIPT TO INSTALL MINECRAFT AND FORGE
# PREREQUISITES: MUST HAVE EITHER ORACLE JAVA JDK OR OPEN-JDK INSTALLED
# HOW TO USE: RUN AS THE DESIRED USER
# AUTHOR: JEFFREY REEVES

# GLOBAL VARIABLES

unset MINECRAFT_SERVER_URL
unset MINECRAFT_JAR_NAME
unset MINECRAFT_VERSION

#MINECRAFT_SERVER_URL="https://s3.amazonaws.com/Minecraft.Download/versions/1.10.2/minecraft_server.1.10.2.jar"
#MINECRAFT_JAR_NAME="minecraft_server.1.10.2.jar"
#MINECRAFT_VERSION="1.10.2"

unset FORGE_INSTALLER_URL
unset FORGE_JAR_NAME
unset FORGE_VERSION

#FORGE_INSTALLER_URL="http://files.minecraftforge.net/maven/net/minecraftforge/forge/1.10.2-12.18.1.2011/forge-1.10.2-12.18.1.2011-installer.jar"
#FORGE_JAR_NAME="forge-1.10.2-12.18.1.2011-installer.jar"
#FORGE_VERSION="12.18.1.2011"

# import variables from config file
CONFIG=/etc/minecraft-forge.conf
[ -f $CONFIG ] && . $CONFIG

# MAIN

echo "This script will install Minecraft ${MINECRAFT_VERSION} and Forge ${FORGE_VERSION} at ${HOME}/minecraft"


# CREATE THE MINECRAFT DIRECTORY

echo "Creating minecraft directory..."
mkdir ${HOME}/minecraft
echo "Directory created successfully"


# ENTER THE MINECRAFT DIRECTORY

echo "Entering minecraft directory at ${HOME}/minecraft..."
cd ${HOME}/minecraft
echo "Inside minecraft directory"


# DOWNLOAD MINECRAFT

echo "Downloading Minecraft server..."
wget ${MINECRAFT_SERVER_URL}
MINECRAFT_DOWNLOAD_STATUS="$?"

echo "Successfully downloaded Minecraft server (${MINECRAFT_JAR_NAME})"


# ACCEPT THE EULA

echo "eula=true" > eula.txt


# DOWNLOAD FORGE

echo "Downloading Forge installer..."
wget ${FORGE_INSTALLER_URL}
FORGE_DOWNLOAD_STATUS="$?"

echo "Successfully downloaded Forge (${FORGE_JAR_NAME})"


# INSTALL FORGE

echo "Running Forge installer..."
java -jar ${FORGE_JAR_NAME} --installServer
