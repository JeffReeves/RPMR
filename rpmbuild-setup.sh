#!/bin/bash

# AUTHOR: Jeffrey Reeves
# https://github.com/JeffReeves
#
# PURPOSE:
# 1. Install the rpmbuild command for building RPMs
# 2. Create six necessary directories for the rpmbuild environment
# 3. Create a basic .rpmmacros file to specify the %_topdir value
# 4. Create a default project directory containing a project template


#
# [FUNCTIONS]
#

make_directory() {
# PURPOSE:
# makes a directory if it does not exist

# PARAMS:
# $1  = directory to be made

	# ensure a parameter was passed
	if [ -z "$1" ]; then
		echo "[ERROR] no parameter passed to make_directory()"
		echo "[HELP] pass directory path (ex. /home/<user>/projectdir)"
		return 1
	fi
	
	# get the directory
	local DIR="$1"
	shift
	
	# check that the directory exists
	if [ ! -d "${DIR}" ]; then
		echo "[NOTICE] ${DIR} does not exist"
		mkdir -p "${DIR}"
		if [ $? -eq 0 ]; then
			echo "[SUCCESS] ${DIR} created successfully"
		else
			echo "[ERROR] ${DIR} could not be created"
			return 2
		fi
	fi
}

check_directories() {
# PURPOSE:
# checks if a directory and its subdirectories exist
# makes the directory and its subdirectories if the do not exist

# PARAMS:
# $1  = root directory
# $2+ = subdirectories

	# ensure a rootdir parameter was passed
	if [ -z "$1" ]; then
		echo "[ERROR] no parameter passed to check_directories()"
		echo "[HELP] pass directory path (ex. /home/<user>)"
		return 1
	fi
	
	# get the root directory
	local ROOTDIR="$1"
	shift
	
	# check that the rootdir exists
	if [ ! -d "${ROOTDIR}" ]; then
		echo "[NOTICE] ${ROOTDIR} does not exist"
		mkdir -p "${ROOTDIR}"
		if [ $? -eq 0 ]; then
			echo "[SUCCESS] ${ROOTDIR} created successfully"
		else
			echo "[ERROR] ${ROOTDIR} could not be created"
			return 2
		fi
	fi
	
	# get all subdirectories
	local SUBDIRS="$@"
	local NUMDIRS="$#"
	#echo "[DEBUG] parameters passed: ${SUBDIRS}"
	#echo "[DEBUG] number of parameters: ${NUMDIRS}"
	
	# ensure additional subdirectory parameters were passed
	if [ -z "${SUBDIRS}" ]; then
		echo "[ERROR] no subdirectories passed to check_directories()"
		echo "[HELP] pass subdirectories (ex. check_directories '~/' 'BUILD' 'BUILDROOT')" 
		return 2
	fi
	
	# loop through each subdirectory passed 
	for i in ${SUBDIRS}; do
		#echo "[DEBUG] checking: $i"
		
		# check that they exist as directories
		if [ ! -d "${ROOTDIR}/$i" ]; then
			echo "[NOTICE] directory $i does not exist in ${ROOTDIR}"
			
			# make missing directory
			mkdir -p "${ROOTDIR}/$i"
			if [ $? -eq 0 ]; then
				echo "[SUCCESS] directory $i created successfully"
			else
				echo "[ERROR] directory $i could not be created"
				return 3
			fi
		else
			#echo "[DEBUG] $i directory exists"
			shift
		fi
	done
}


#
# [GLOBAL VARIABLES]
#

# user's home directory
if [ -z "$HOME" ]; then
	export HOME=~/
fi

# main conf file 
MAIN_CONF="${HOME}/rpmr/rpmr.conf"

# import main conf file, if it exists
if [ -s "${MAIN_CONF}" ]; then
	source ${MAIN_CONF}

	echo '[DEBUG] TOPDIR:'
	echo "${TOPDIR}"

	echo '[DEBUG] RPMBUILD_DIR:'
	echo "${RPMBUILD_DIR}"
	
	echo '[DEBUG] PROJECT_HOME:'
	echo "${PROJECT_HOME}"
else
	echo "[DEBUG] NO CONF FILE FOUND"
	
	# make conf file directory
	make_directory "${HOME}/rpmr"

	# directory where RPMs will be built
	echo "[QUESTION] RPM Build Directory" 
	echo "Please enter the full path to a directory you wish to build RPMs within:"
	echo "(Default: ${HOME}/rpmr/rpmbuild)"
	read TOPDIR

	if [ -z ${TOPDIR} ]; then
		echo "[NOTICE] No path provided for RPM Build Directory."
		echo "Defaulting to ${HOME}/rpmr/rpmbuild"
		TOPDIR="${HOME}/rpmr/rpmbuild"
	fi
	
	# strip out prefix to get rpmbuild directory name
	RPMBUILD_DIR=$(echo "${TOPDIR}" | sed 's/.*\///g')

	# main directory where projects will be stored
	echo "[QUESTION] Project Directory" 
	echo "Please enter the full path to a directory you wish to store your projects in:"
	echo "(Default: ${HOME}/rpmr/projectdir)"
	read PROJECT_HOME

	if [ -z ${PROJECT_HOME} ]; then
		echo "[NOTICE] No path provided for Project Directory."
		echoh "Defaulting to ${HOME}/rpmr/projectdir"
		PROJECT_HOME="${HOME}/rpmr/projectdir"
	fi

	cat >${MAIN_CONF} <<EOL
RPMBUILD_DIR="${RPMBUILD_DIR}"	
TOPDIR="${TOPDIR}"	
PROJECT_HOME="${PROJECT_HOME}"
EOL
	if [ $? -eq 0 ]; then
		echo "[SUCCESS] Created ${MAIN_CONF}"
	else
		echo "[ERROR] Failed to create ${MAIN_CONF}"
		return 1
	fi

fi


#
# [STEP 1]: Install rpmbuild
#

# check if the rpmbuild command is already installed
RPMBUILD=`which rpmbuild`
if [ -z "${RPMBUILD}" ]; then
	echo "[ERROR] rpmbuild command not found"
	echo "[HELP] installing rpmbuild..."
	echo "[CMD] sudo yum install -y rpm-build"
	sudo yum install -y rpm-build
else
	echo "[SUCCESS] rpmbuild command is available"
fi


#
# [STEP 2]: Create the six directories needed for the rpmbuild environment
#

# create this directory and its subdirectories if they do not exist
check_directories "${TOPDIR}" 'BUILD' 'BUILDROOT' 'RPMS' 'SOURCES' 'SPECS' 'SRPMS'
if [ $? -eq 0 ]; then
	echo "[SUCCESS] ${TOPDIR} exists and contains all directories needed"
else
	echo "[ERROR] STEP 2 failed"
	return 2
fi


#
# [STEP 3]: Create a basic .rpmmacros file to specify default %_topdir
#

# set the %_topdir value to the directory made in STEP 2
echo '%_topdir ' ${TOPDIR} > ${HOME}/.rpmmacros
if [ $? -eq 0 ]; then
	echo "[SUCCESS] .rpmmacros file created at ${HOME}"
else
	echo "[ERROR] STEP 3 failed"
	return 3
fi

#
# [STEP 4]: Create a default project directory containing a project template
#

# supporting subdirectories 
BIN_DIR="${PROJECT_HOME}/project-template/usr/local/bin"
DOC_DIR="${PROJECT_HOME}/project-template/usr/share/doc"
CONF_DIR="${PROJECT_HOME}/project-template/usr/etc"

# create the project directories
make_directory "${PROJECT_HOME}"
make_directory "${BIN_DIR}"
make_directory "${DOC_DIR}"
make_directory "${CONF_DIR}"

echo "[SUCCESS] Created default project directory and supporting subdirectories"

#
# [FINISH] Prompt user with a getting started guide
#


# prompt the user to build the test RPM if they desire
echo "[COMPLETE] rpmbuild-setup ran successfully!"
echo ""
echo "[HELP] GETTING STARTED WITH RPM BUILDING USING RPMR:"
echo "1. All RPM projects must be within a subdirectory of ${PROJECT_HOME}."
echo "2. The name of the subdirectory should be the name of your project."
echo "3. The project-template directory is an example of how to organize your project."
echo "4. Run the create-spec script to create a project.conf and a .spec file for your project's RPM."
echo "5. The create-spec script will output the rpmbuild command needed to create the RPM."
echo "6. Check the rpmbuild/RPMS directory for your build RPM."
