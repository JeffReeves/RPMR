#!/bin/bash
# purpose: add all remotes for repo
# author: Jeff Reeves

# define repository's stub for the URL
REPO_STUB='RPMR'

# create the repo directory on bridges
ssh git@bridges "mkdir /git/RPMR.git && cd /git/RPMR.git && git config --global init.defaultBranch main && git init --bare && sed -i 's/master/main/' /git/rpi4-custom-os.git/HEAD"

# add bridges to git remote list
git remote add bridges git@bridges:/git/RPMR.git

# add gitlab to git remote list
git remote add gitlab git@gitlab.com:JeffReeves/RPMR.git

# add github to git remote list
git remote add github git@github.com:JeffReeves/RPMR.git

# update origin to bridges
git remote set-url origin git@bridges:/git/RPMR.git

# view all remotes
git remote -v

# open settings for gitlab and github in browser
#explorer.exe "https://gitlab.com/JeffReeves/RPMR/-/settings/repository"
#explorer.exe "https://gitlab.com/JeffReeves/RPMR/-/branches"
#explorer.exe "https://github.com/JeffReeves/RPMR/settings/branches"
#explorer.exe "https://github.com/JeffReeves/RPMR/branches"

