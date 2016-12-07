#!/bin/bash

# AUTHOR:
# Jeffrey Reeves
# https://github.com/JeffReeves
#
# PURPOSE:
# 1. Generate a .spec file for RPM building using a template
# 2. Generate a project directory within the BUILD directory
# 3. Generate a project directory within the BUILDROOT directory
# 4. Copy project files into the BUILD / BUILDROOT project directories
# 5. Create a cleanup script to remove everything but the .rpm file
# 6. Display a prompt to the user to build the RPM
#
# PREREQUISITES:
# 1. rpmbuild must be installed
# 2. .rpmmacro must specify %_topdir as TOPDIR
# 3. TOPDIR directory must contain six rpmbuild directories:
#   BUILD, BUILDROOT, RPMS, SOURCES, SPECS, SRPMS
#
# NOTES:
# 1. Run the rpmbuild-setup.sh file to meet all prerequisities
# 2. Place your project files within a $HOME/projectdir/<project-name> directory
# 3. Run the clean-rpmbuild.sh file to delete project files in the rpmbuild directory
#

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


#
# [GLOBAL VARIABLES] Read from Conf file, or create it if one does not exist
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
	
	echo "[SUCCESS] CONF FILE FOUND AND READ"

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
# [PROJECT DETAILS]
#

# get the directory the user was in when this script was executed 
PWD=$(pwd)

# ask for directory the project is in so we can cd to it
echo "[QUESTION] PROJECT DIRECTORY"
echo "Please enter the full path to the project directory:"
echo "(Default: ${PWD})"
read PROJECT_DIRECTORY

if [ -z ${PROJECT_DIRECTORY} ]; then
	echo "Defaulting to ${PWD}"
	PROJECT_DIRECTORY="${PWD}"
else
	cd ${PROJECT_DIRECTORY}
fi

# get the current directory again (in case it changed)
PWD=$(pwd)

# strip out prefix to hopefully get the project's name
POSSIBLE_PROJECT_NAME=$(echo "${PWD}" | sed 's/.*\///g')

# project conf file
PROJECT_CONF="${PROJECT_DIRECTORY}/project.conf"

# import project conf file, if it exists
if [ -s "${PROJECT_CONF}" ]; then
	source ${PROJECT_CONF}
	
	echo "[SUCCESS] PROJECT CONF FILE FOUND AND READ"
	
	echo "[NOTICE] PROJECT DETAILS:"
	echo "PROJECT_NAME = ${PROJECT_NAME}"
	echo "VERSION = ${VERSION}"
	echo "RELEASE = ${RELEASE}"
	echo "ARCHITECTURE = ${ARCHITECTURE}"
	echo "SUMMARY = ${SUMMARY}"
	echo "DESCRIPTION = ${DESCRIPTION}"
	echo "LICENSE = ${LICENSE}"
	echo "VENDOR = ${VENDOR}"
	echo "GROUP = ${GROUP}"

else
	echo "[NOTICE] NO PROJECT CONF FILE FOUND"
	
	# make conf file directory
	make_directory "${PROJECT_DIRECTORY}"
	
	# ask for project details to create a conf file

	# PROJECT NAME
	echo "[QUESTION] NAME" 
	echo "Please enter name of the project:"
	echo "(Default: ${POSSIBLE_PROJECT_NAME})"
	read PROJECT_NAME

	if [ -z ${PROJECT_NAME} ]; then
		echo "Defaulting to ${POSSIBLE_PROJECT_NAME}"
		PROJECT_NAME="${POSSIBLE_PROJECT_NAME}"
	fi
	
	# VERSION
	echo "[QUESTION] VERSION" 
	echo "Please enter version of the project (major.minor):"
	echo "(Default: 1.0)"
	read VERSION

	if [ -z ${VERSION} ]; then
		echo "Defaulting to 1.0"
		VERSION="1.0"
	fi
	
	# RELEASE
	echo "[QUESTION] RELEASE" 
	echo "Please enter release of the project:"
	echo "(Default: 0)"
	read RELEASE

	if [ -z ${RELEASE} ]; then
		echo "Defaulting to 0"
		RELEASE="0"
	fi
	
	# ARCHITECTURE
	echo "[QUESTION] ARCHITECTURE" 
	echo "Please enter architecture of the project (x86_64, i686, noarch, etc.):"
	echo "(Default: x86_64)"
	read ARCHITECTURE

	if [ -z ${ARCHITECTURE} ]; then
		echo "Defaulting to x86_64"
		ARCHITECTURE="x86_64"
	fi
	
	# SUMMARY
	echo "[QUESTION] SUMMARY" 
	echo "Please enter a summary for the project:"
	echo "(Default: 'This is a test')"
	read SUMMARY

	if [ -z ${SUMMARY} ]; then
		echo "Defaulting to 'This is a test'"
		SUMMARY="This is a test"
	fi
	
	# DESCRIPTION
	echo "[QUESTION] DESCRIPTION" 
	echo "Please enter a description for the project:"
	echo "(Default: ${SUMMARY})"
	read DESCRIPTION

	if [ -z ${DESCRIPTION} ]; then
		echo "Defaulting to ${SUMMARY}"
		DESCRIPTION="${SUMMARY}"
	fi
	
	# LICENSE
	echo "[QUESTION] LICENSE" 
	echo "Please enter a license for the project:"
	echo "(Default: 'None')"
	read LICENSE

	if [ -z ${LICENSE} ]; then
		echo "Defaulting to 'None'"
		LICENSE="None"
	fi
	
	# VENDOR
	echo "[QUESTION] VENDOR" 
	echo "Please enter the vendor name for the project:"
	echo "(Default: 'No One')"
	read VENDOR

	if [ -z ${VENDOR} ]; then
		echo "Defaulting to 'No One'"
		VENDOR="No One"
	fi
	
	# GROUP
	echo "[QUESTION] GROUP" 
	echo "Please enter the group for the project:"
	echo "(Default: 'Applications/Productivity')"
	read GROUP

	if [ -z ${GROUP} ]; then
		echo "Defaulting to 'Applications/Productivity'"
		GROUP="Applications/Productivity"
	fi

	# write everything to the project's conf file
	cat >${PROJECT_CONF} <<EOL
PROJECT_NAME="${PROJECT_NAME}"	
VERSION="${VERSION}"	
RELEASE="${RELEASE}"
ARCHITECTURE="${ARCHITECTURE}"	
SUMMARY="${SUMMARY}"	
DESCRIPTION="${DESCRIPTION}"
LICENSE="${LICENSE}"	
VENDOR="${VENDOR}"	
GROUP="${GROUP}"
EOL
	if [ $? -eq 0 ]; then
		echo "[SUCCESS] Created ${PROJECT_CONF}"
	else
		echo "[ERROR] Failed to create ${PROJECT_CONF}"
		return 1
	fi

fi

#PROJECT_NAME="rpmr"
#VERSION="1.0"
#RELEASE="0"
#ARCHITECTURE="x86_64"
#SUMMARY="Reduces RPM building to a simple config file"
#DESCRIPTION="Reduces RPM building to a simple config file"
#LICENSE="MIT"
#VENDOR="Alchemist.Digital"
#GROUP="Development/Tools"

# source if building from .tar
SOURCE=''

# master directory that contains all projects
#PROJECT_HOME="${HOME}/projectdir" # now read from rpmr.conf file

# directory containing current project files
PROJECT_DIR="${PROJECT_HOME}/${PROJECT_NAME}"

# all files within the project directory
PROJECT_FILES=$(find ${PROJECT_DIR} -type f -follow -print | sed -e "s:${PROJECT_DIR}::g")

# documentation files
DOC_DIR="/usr/share/doc"
DOC_PREFIX='%attr(0644,root,root) %doc %name-%version'
DOC_FILES=$(echo "${PROJECT_FILES}" | grep "${DOC_DIR}")
DOC_FILES=$(echo "${DOC_FILES}" | sed -e "s:${DOC_DIR}:${DOC_PREFIX}:g")

# configuration files
CONFIG_DIR="/usr/etc"
CONFIG_PREFIX='%config(noreplace) /usr/etc/%name/'
CONFIG_FILES=$(echo "${PROJECT_FILES}" | grep "${CONFIG_DIR}")
CONFIG_FILES=$(echo "${CONFIG_FILES}" | sed -e "s:${CONFIG_DIR}:${CONFIG_PREFIX}:g")

# BUILDROOT files
BUILDROOT_FILES=$(echo "${PROJECT_FILES}" | grep -v "${DOC_DIR}")
BUILDROOT_FILES=$(echo "${BUILDROOT_FILES}" | grep -v "${CONFIG_DIR}")

# default file attributes
DEFATTR='%defattr(0755,root,root)'

# files to be included in the RPM
FILES=$(cat <<-END
${DEFATTR}
${BUILDROOT_FILES}
${CONFIG_FILES}
${DOC_FILES}
END
)

# occurs after building
# Note: if left blank, default behavior is to rm -rf the project directories
CLEAN=$(cat <<-END
echo "Not cleaning up because more building is going to happen."

END
)

# occurs during pre-installation
PRE=$(cat <<-END
echo "Preparing for installation..."

END
)

# occurs after installation
POST=$(cat <<-END
echo "Installation successful."

END
) 

# occurs during pre-uninstallation
PREUN=$(cat <<-END
echo "Preparing to uninstall..."

END
)

# occurs after uninstallation
POSTUN=$(cat <<-END
echo "Uninstall completed successfully."

END
)

#
# [RPMBUILD VARIABLES]
#

# directory name where RPMs will be built
#RPMBUILD_DIR="rpmbuild" # now read from rpmr.conf file

# top directory to build RPMs in
#TOPDIR="${HOME}/${RPMBUILD_DIR}" # now read from rpmr.conf file

# file must be named '<name-of-rpm>-<version>-<release>.spec'
SPEC_FILE="${TOPDIR}/SPECS/${PROJECT_NAME}-${VERSION}-${RELEASE}.spec"

# BUILD directory must be named 'BUILD/<rpm-name>-<version>'
BUILD_DIR="${TOPDIR}/BUILD/${PROJECT_NAME}-${VERSION}"

# BUILDROOT directory must be named 'BUILDROOT/<rpm-name>-<version>-<release>.<architecture>'
BUILDROOT_DIR="${TOPDIR}/BUILDROOT/${PROJECT_NAME}-${VERSION}-${RELEASE}.${ARCHITECTURE}"

# config file project directory must be named $BUILDROOT/usr/etc/<rpm-name>
BUILDROOT_CONFIG_DIR="${BUILDROOT_DIR}${CONFIG_DIR}/${PROJECT_NAME}"

# clean file for removing SPEC file and BUILD / BUILDROOT project directories
CLEAN_FILE="${HOME}/clean-${RPMBUILD_DIR}.sh"

#
# [FUNCTIONS]
#


#
# [STEP 1]: Create a template .spec file
#

cat >${SPEC_FILE} <<EOL
Name:       ${PROJECT_NAME}
Version:    ${VERSION}
Release:    ${RELEASE}
Summary:    ${SUMMARY}
License:    ${LICENSE}
Vendor:     ${VENDOR}
Group:      ${GROUP}

%description
${DESCRIPTION}

%clean
${CLEAN}

%pre
${PRE}

%post
${POST}

%preun
${PREUN}

%postun
${POSTUN}

%files
${FILES}
EOL
if [ $? -eq 0 ]; then
	echo "[SUCCESS] ${PROJECT_NAME}-${VERSION}-${RELEASE}.spec file created at ${TOPDIR}/SPECS"
else
	echo "[ERROR] ${PROJECT_NAME}-${VERSION}-${RELEASE}.spec file could not be created"
	return 1
fi


#
# [STEP 2]: Create a project directory within the BUILD directory
#

mkdir -p "${BUILD_DIR}"
if [ $? -eq 0 ]; then
	echo "[SUCCESS] ${PROJECT_NAME}-${VERSION} directory created at ${TOPDIR}/BUILD"
else
	echo "[ERROR] ${PROJECT_NAME}-${VERSION} directory could not be created at ${TOPDIR}/BUILD"
	return 2
fi


#
# [STEP 3]: Create a project directory within the BUILDROOT directory
#

mkdir -p "${BUILDROOT_DIR}"
if [ $? -eq 0 ]; then
	echo "[SUCCESS] ${PROJECT_NAME}-${VERSION}-${RELEASE}.${ARCHITECTURE} directory created at ${TOPDIR}/BUILDROOT"
else
	echo "[ERROR] ${PROJECT_NAME}-${VERSION}-${RELEASE}.${ARCHITECTURE} directory could not be created at ${TOPDIR}/BUILDROOT"
	return 3
fi


#
# [STEP 4]: Copy project files into the BUILD / BUILDROOT project directories
#

# recursively copy all directories in the project directory to the BUILDROOT directory
cp -a ${PROJECT_DIR}/* ${BUILDROOT_DIR}
if [ $? -eq 0 ]; then
	echo "[SUCCESS] Project files:"
	echo "${PROJECT_FILES}"
	echo "copied to ${BUILDROOT_DIR}"
else
	echo "[ERROR] Project files:"
	echo "${PROJECT_FILES}"
	echo "could not be copied to ${BUILDROOT_DIR}"
	return 4
fi

# move the /usr/share/doc files into the BUILD directory, if they exist
DOCS=$(find "${BUILDROOT_DIR}${DOC_DIR}" -maxdepth 1 -type f) 
DOC_NAMES=$(echo "${DOCS}" | sed -e "s:${BUILDROOT_DIR}::g")
if [ -n "${DOCS}" ]; then
	find "${BUILDROOT_DIR}${DOC_DIR}" -maxdepth 1 -type f -exec mv {} ${BUILD_DIR} \;
	if [ $? -eq 0 ]; then
		echo "[SUCCESS] moved the following documentation files:"
		echo "${DOC_NAMES}" 
		echo "to ${BUILD_DIR} successfully"
	else
		echo "[ERROR] Unable to move the following documentation files:"
		echo "${DOC_NAMES}" 
		echo "to ${BUILD_DIR}"
		return 4
	fi
	
	# delete redundant BUILDROOT /usr/share/doc directory
	rm -rf ${BUILDROOT_DIR}${DOC_DIR}
	if [ $? -eq 0 ]; then
		echo "[SUCCESS] deleted the redundant ${BUILDROOT_DIR}${DOC_DIR} directory"
	else
		echo "[ERROR] Unable to deleted the redundant ${BUILDROOT_DIR}${DOC_DIR} directory"
		return 4
	fi
fi

# move the /usr/etc config files into the BUILDROOT/usr/etc/<project_name> directory, if they exist
CONFIGS=$(find "${BUILDROOT_DIR}${CONFIG_DIR}" -maxdepth 1 -type f) 
CONFIG_NAMES=$(echo "${CONFIGS}" | sed -e "s:${BUILDROOT_DIR}::g")
if [ -n "${CONFIGS}" ]; then
	# make project directory in BUILDROOT/etc/usr
	mkdir -p "${BUILDROOT_CONFIG_DIR}"
	
	find "${BUILDROOT_DIR}${CONFIG_DIR}" -maxdepth 1 -type f -exec mv {} ${BUILDROOT_CONFIG_DIR} \;
	if [ $? -eq 0 ]; then
		echo "[SUCCESS] moved the following configuration files:"
		echo "${CONFIG_NAMES}" 
		echo "to ${BUILDROOT_CONFIG_DIR} successfully"
	else
		echo "[ERROR] Unable to move the following configuration files:"
		echo "${CONFIG_NAMES}" 
		echo "to ${BUILDROOT_CONFIG_DIR}"
		return 4
	fi
fi


# delete the project.conf file from the BUILDROOT
if [ -f "${BUILDROOT_DIR}/project.conf" ]; then
	rm -rf "${BUILDROOT_DIR}/project.conf"
	if [ $? -eq 0 ]; then
		echo "[SUCCESS] Deleted the redundant ${BUILDROOT_DIR}/project.conf file"
	else
		echo "[ERROR] Unable to delete the redundant ${BUILDROOT_DIR}/project.conf file"
		return 4
	fi
fi

# 
# [STEP 5]: Create a cleanup script to remove everything but the .rpm file
#

# write the cleanup script
cat >${CLEAN_FILE} <<EOL
#!/bin/bash
# PURPOSE:
# 1. Remove SPEC file and BUILD / BUILDROOT project directories from ${TOPDIR}
# 2. Removes itself

# remove BUILD project directory
rm -rf ${BUILD_DIR}
if [ $? -eq 0 ]; then
	echo "[SUCCESS] ${BUILD_DIR} deleted successfully"
else
	echo "[ERROR] ${BUILD_DIR} could not be deleted"
fi

# remove BUILDROOT project directory
rm -rf ${BUILDROOT_DIR}
if [ $? -eq 0 ]; then
	echo "[SUCCESS] ${BUILDROOT_DIR} deleted successfully"
else
	echo "[ERROR] ${BUILDROOT_DIR} could not be deleted"
fi

# remove SPEC file
rm -rf ${SPEC_FILE}
if [ $? -eq 0 ]; then
	echo "[SUCCESS] ${SPEC_FILE} deleted successfully"
else
	echo "[ERROR] ${SPEC_FILE} could not be deleted"
fi

# remove itself
rm -rf ${CLEAN_FILE}
if [ $? -eq 0 ]; then
	echo "[SUCCESS] ${CLEAN_FILE} deleted successfully"
else
	echo "[ERROR] ${CLEAN_FILE} could not be deleted"
fi
EOL
if [ $? -eq 0 ]; then
	echo "[SUCCESS] ${CLEAN_FILE} deleted successfully"
else
	echo "[ERROR] ${CLEAN_FILE} could not be created"
	return 5
fi

# give it execute permissions
chmod +x "${CLEAN_FILE}"
if [ $? -eq 0 ]; then
	echo "[SUCCESS] ${CLEAN_FILE} granted execute permissions"
else
	echo "[ERROR] ${CLEAN_FILE} did not receive execute permissions"
	return 5
fi


#
# [STEP 6]: Prompt the user to build the RPM if they desire
#

echo "[COMPLETE] create-spec.sh ran successfully!"
echo ""
echo "[HELP] To clean up the project files and directories afterwards:"
echo "$ . ~/clean-rpmbuild.sh"
echo ""
echo "[HELP] To build the RPM from the generated spec file:"
echo "$ rpmbuild -bb ${SPEC_FILE}"
