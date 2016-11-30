#!/bin/bash

# AUTHOR: Jeffrey Reeves
# PURPOSE:
# 1. Install the rpmbuild command for building RPMs
# 2. Create six necessary directories for the rpmbuild environment
# 3. Create a basic .rpmmacros file to specify the %_topdir value
# 4. Create a template .spec file and related build directories


#
# [GLOBAL VARIABLES]
#

# user's home directory
if [ -z "$HOME" ]; then
	HOME=~/
fi

# directory name where RPMs will be built
RPMBUILD_DIR="rpmbuild"

# top directory to build RPMs in
TOPDIR="${HOME}/${RPMBUILD_DIR}"

# RPM project details 
PROJECT_NAME="test-rpm"
VERSION="1.0"
RELEASE="0"
ARCHITECTURE="x86_64"
SUMMARY="Tests the creation of RPMs"
LICENSE="NONE"
VENDOR="No One"
GROUP="Application/Text"

# file must be named '<name-of-rpm>-<version>-<release>.spec'
SPEC_FILE="${TOPDIR}/SPECS/${PROJECT_NAME}-${VERSION}-${RELEASE}.spec"

# BUILD directory must be named 'BUILD/<rpm-name>-<version>'
BUILD_DIR="${TOPDIR}/BUILD/${PROJECT_NAME}-${VERSION}"

# BUILDROOT directory must be named 'BUILDROOT/<rpm-name>-<version>-<release>.<architecture>'
BUILDROOT_DIR="${TOPDIR}/BUILDROOT/${PROJECT_NAME}-${VERSION}-${RELEASE}.${ARCHITECTURE}"

#
# [FUNCTIONS]
#

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
		echo "[ERROR] ${ROOTDIR} does not exist"
		mkdir -p "${ROOTDIR}"
		if [ $? -eq 0 ]; then
			echo "[SUCCESS] ${ROOTDIR} created successfully"
		else
			echo "[ERROR] ${ROOTDIR} could not be created"
			return 3
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
			echo "[ERROR] directory $i does not exist in ${ROOTDIR}"
			
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
echo '%_topdir %(echo $HOME)/'${RPMBUILD_DIR} > ${HOME}/.rpmmacros
if [ $? -eq 0 ]; then
	echo "[SUCCESS] .rpmmacros file created at ${HOME}"
else
	echo "[ERROR] STEP 3 failed"
	return 3
fi

#
# [STEP 4]: Create a template .spec file and all related directories
#

# write the test-rpm spec file
cat >${SPEC_FILE} <<EOL
Name:       ${PROJECT_NAME}
Release:    ${RELEASE}
Summary:    ${SUMMARY}
License:    ${LICENSE}
Version:    ${VERSION}
Vendor:     ${VENDOR}
Group:      ${GROUP}

%description
This is a test RPM package

%clean
echo "Not cleaning up because more building is going to happen."

%pre
echo "Preparing for installation..."

%post
echo "Installation successful. Review /usr/share/doc/${PROJECT_NAME} for help."

%preun
echo "Preparing to uninstall..."

%postun
echo "Uninstall completed successfully."

%files
%defattr(0755,root,root)
/usr/share/${PROJECT_NAME}/test.txt
%attr(0644,root,root) %doc %name-%version/README
EOL
if [ $? -eq 0 ]; then
	echo "[SUCCESS] ${PROJECT_NAME}-${VERSION}-${RELEASE}.spec file created at ${TOPDIR}/SPECS"
else
	echo "[ERROR] STEP 4 failed - .spec file could not be created"
	return 4
fi

# create the project directory within the BUILD directory
mkdir -p "${BUILD_DIR}"
if [ $? -eq 0 ]; then
	echo "[SUCCESS] ${PROJECT_NAME}-${VERSION} directory created at ${TOPDIR}/BUILD"
else
	echo "[ERROR] STEP 4 failed - project directory could not be created at ${TOPDIR}/BUILD"
	return 4
fi

# add a README file within the project's BUILD directory
cat >${BUILD_DIR}/README <<EOL
This is the readme for test-rpm.

This RPM only creates a txt file in: /usr/share/${PROJECT_NAME}

To uninstall this package run:
$ sudo rpm -e ${PROJECT_NAME}
EOL
if [ $? -eq 0 ]; then
	echo "[SUCCESS] README file created at ${BUILD_DIR}"
else
	echo "[ERROR] STEP 4 failed - README file could not be created at BUILDROOT/usr/share/${PROJECT_NAME}"
	return 4
fi

# create the project's BUILDROOT directory to represent the 
#    root directory of the installed machine
mkdir -p "${BUILDROOT_DIR}"
if [ $? -eq 0 ]; then
	echo "[SUCCESS] ${PROJECT_NAME}-${VERSION}-${RELEASE}.${ARCHITECTURE} directory created at ${TOPDIR}/BUILDROOT"
else
	echo "[ERROR] STEP 4 failed - project directory could not be created at ${TOPDIR}/BUILDROOT"
	return 4
fi

# create a /usr/share/<project-name> directory within the BUILDROOT
mkdir -p "${BUILDROOT_DIR}/usr/share/${PROJECT_NAME}"
if [ $? -eq 0 ]; then
	echo "[SUCCESS] /usr/share/${PROJECT_NAME} directory created at ${BUILDROOT_DIR}"
else
	echo "[ERROR] STEP 4 failed - /usr/share/${PROJECT_NAME} could not be created in BUILDROOT"
	return 4
fi

# create a test.txt file within the last directory
cat >${BUILDROOT_DIR}/usr/share/${PROJECT_NAME}/test.txt <<EOL
This is just a test RPM

Please review the /usr/share/docs/${PROJECT_NAME}/README file for more information.
EOL
if [ $? -eq 0 ]; then
	echo "[SUCCESS]  test.txt file created at ${BUILDROOT_DIR}/usr/share/${PROJECT_NAME}"
else
	echo "[ERROR] STEP 4 failed - test.txt file could not be created at ${BUILDROOT_DIR}/usr/share/${PROJECT_NAME}"
	return 4
fi

# prompt the user to build the test RPM if they desire
echo "[COMPLETE] $1 ran successfully!"
echo "[HELP if you would like to build the test RPM created by this script:"
echo "$ rpmbuild -bb ${SPEC_FILE}"
