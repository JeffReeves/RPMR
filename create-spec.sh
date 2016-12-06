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
# [PROJECT DETAILS]
#

PROJECT_NAME="rpmr"
VERSION="1.0"
RELEASE="0"
ARCHITECTURE="x86_64"
SUMMARY="Reduces RPM building to a simple config file"
DESCRIPTION="Reduces RPM building to a simple config file"
LICENSE="MIT"
VENDOR="Alchemist.Digital"
GROUP="Development/Tools"

# source if building from .tar
SOURCE=''

# master directory that contains all projects
PROJECT_HOME="${HOME}/projectdir"

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
RPMBUILD_DIR="rpmbuild"

# top directory to build RPMs in
TOPDIR="${HOME}/${RPMBUILD_DIR}"

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
