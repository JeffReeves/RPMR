##Setting up the Environment


To build RPM packages you must install the RPM Builder:
```
$ sudo yum install -y rpm-build
```

After installing the RPM Builder, set up your home directory so that it has an rpmbuild directory for you to build RPMs under your user:
```
$ mkdir -p ~/rpmbuild/{BUILD,BUILDROOT,RPMS,SOURCES,SPECS,SRPMS}
```

The above mkdir command creates the following folders:
/home/<user>/rpmbuild/BUILD
/home/<user>/rpmbuild/BUILDROOT
/home/<user>/rpmbuild/RPMS
/home/<user>/rpmbuild/SOURCES
/home/<user>/rpmbuild/SPECS
/home/<user>/rpmbuild/SRPMS


Then create an .rpmmacros file to ensure that the building of RPMs occurs within the directories you made:
```
$ echo '%_topdir %(echo $HOME)/rpmbuild' > ~/.rpmmacros
```

The above command creates a /home/<user>/.rpmmacros file that contains:
%_topdir %(echo $HOME)/rpmbuild

The purpose of this line is to set the %_topdir value so that it will be /home/<user>/rpmbuild.


You should now be ready to begin making your RPMs.



##Creating RPMs

Create a .spec file within the SPEC directory:
```
$ vi ~/rpmbuild/SPECS/test-rpm-1.0-0.spec
```

The naming conventions for the .spec file are:
<name-of-rpm>-<version>-<release>.spec


Insert the following text within the file:
```
Name:       test-rpm
Release:    0
Summary:    Tests the creation of RPMs
License:    None
Version:    1.0
Vendor:     No One
Group:      Applications/Text

%description
This is a test RPM package

%clean
echo "Not cleaning up because more building is going to happen."

%pre
echo "Preparing for installation..."

%post
echo "Installation successful. Review /usr/share/doc/test-rpm for help."

%preun
echo "Preparing to uninstall..."

%postun
echo "Uninstall completed successfully."

%files
%defattr(0755,root,root)
/usr/share/test-rpm/test.txt
%attr(0644,root,root) %doc %name-%version/README
```

The above file can be broken down into three major sections:
1.	Information about this RPM
2.	Section Tags describing the RPM and what to do during specific events
3.	The files and their attributes

If the clean tag describes what happens after building the RPM. If this section is left out the default behavior is to delete everything in the BUILD and BUILDROOT directories.

The pre and post tags represent what to do before and after installation, respectively.

The preun and postun tags represent what to do before and after uninstallation, respectively.

The files tag contains a list of all the files that are going into the RPM. 

The defattr tag defines the default attributes of the files listed below it; and the attr tag represents the attributes of the file on the same line as it.

The doc tag indicates that it is a document file and will automatically place the file within /usr/share/docs.

The name and version tags act as macros to represent the values placed in the informational section of the RPM .spec file.


Create a README file in /home/<user>/rpmbuild/BUILD/test-rpm-1.0:
```
$ mkdir ~/rpmbuild/BUILD/test-rpm-1.0
$ vi ~/rpmbuild/BUILD/test-rpm-1.0/README
```

The directory containing the README file must be in the format of <RPM-name>-<version>.


Insert the following text within the file:

This is the readme for test-rpm

This RPM only creates a txt file in /usr/share/test-rpm
To uninstall this package run:
```
$ sudo rpm -e test-rpm
```

This file will end up in /usr/share/test-rpm/README after the RPM is installed, but it must be placed in the BUILD directory so it is added during the build process.


Create a folder to represent the root directory of the RPM inside of /home/<user>/rpmbuild/BUILDROOT:
```
$ mkdir ~/rpmbuild/BUILDROOT/test-rpm-1.0-0.x86_64
```

This directory must be named using the format of <RPM-name>-<version>-<release>.<architecture>.


Create the folders that will be used during the installation of the RPM within this directory:
```
$ mkdir -p ~/rpmbuild/BUILDROOT/test-rpm-1.0-0.x86_64/usr/share/test-rpm
```

The BUILDROOT/test-rpm-1.0-0.x86-64 directory represents the root directory on the machine that the RPM will be installed on. So any folders or files in this directory should match what you want when the RPM is installed. For example, if you want a file to go into the /etc/nginx directory you should make a directory at /home/<user>/rpmbuild/BUILDROOT/test-rpm-1.0-0.x86_64/etc/nginx. 

Create the text file going into the /usr/share/test-rpm directory:
```
$ vi ~/rpmbuild/BUILDROOT/test-rpm-1.0-0.x86_64/usr/share/test-rpm/test.txt
```

Insert the following text within the file:

This is just a test RPM

Please review the /usr/share/docs/test-rpm/README file for more information.


If we were to run the tree command on the /home/<user>/rpmbuild directory at this point we would have the following output:

```
/home/<user>/rpmbuild/
- BUILD
  - test-rpm-1.0
    - README
- BUILDROOT
  - test-rpm-1.0-0.x86_64
    - usr
      - share
        - test-rpm
          - test.txt
- RPMS
- SOURCES
- SPECS
  - test-rpm-1.0-0.spec
- SRPMS
 
11 directories, 3 files
```

Now build the RPM:
```
$ cd ~/rpmbuild/SPECS 
$ rpmbuild -bb test-rpm-1.0-0.spec
```

The .rpm file will now be built and placed within the /home/<user>/rpmbuild/RPMS/x86_64 directory.



##Installing the RPM

Now that we’ve built the .rpm file we can install it with:
```
$ cd ~/rpmbuild/RPMS/x86_64
$ sudo rpm -ivh test-rpm-1.0-0.x86_64.rpm
```

Now you should have a /usr/share/test-rpm directory with a test.txt file in it, and a /usr/share/docs/test-rpm directory with a README in it.



##Uninstalling the RPM

To uninstall the RPM we need to know the name of the RPM package. To find it run this command:
```
$ rpm -qa | grep <partial_name>
```

For example:
```
$ rpm -qa | grep test
```

The output will give you the exact name of the RPM package:
test-rpm-1.0-0.x86_64

Now that we know the exact name of the RPM package we can uninstall it with:
```
$ sudo rpm -e ‘test-rpm-1.0-0.x86_64’
```



