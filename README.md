# RPMR

RPMR (RPM-er) is a handy tool for easily setting up an rpmbuild 
environment and building RPM packages from individual project directories

## Contents

RPMR-1.0-0.x86_64.rpm - .rpm package containig everything you need to use RPMR
README.md - this README file
LICENSE - MIT License for this project

## How to Install

Download the RPM package for RPMS
Install with the RPM command with sudo or as root: 

```rpm -ivh RPMR-1.0-0.x86_64.rpm
``` 

## How to Use 

RPMR will place two main scripts within the /usr/local/bin directory:

- rpmbuild-setup.sh
- create-spec.sh 

Run rpmbuild-setup first:

```rpmbuild-setup
``` 

Follow the onscreen options to set up the rpmbuild environment with RPMR.

Then enter the project directory of your choice (default path is 
~/rpmr/projectdir/<your_project_directory>) and run the create-spec script:

```cd ~/rpmr/projecdir/<my_project_dir>
create-spec
```

Follow the onscreen prompts to ensure your .spec file gets created with
the desired options for your RPM package.

Run the last command from the create-spec output. Example:
```rpmbuild -bb /home/jeff/rpmr/rpmbuild/SPECS/RPMR-1.0-0.spec
```

Lastly, if you want to delete all the directories and files created by 
RPMR in the rpmbuild directory (default is ~/rpmr/rpmbuild) run the 
clean-rpmbuild.sh script that gets placed into your home directory:

```source ~/clean-rpmbuild.sh 
```

## Note

You can manually edit the .spec file in the rpmbuild directory before 
running the rpmbuild command