#!/bin/bash
#
# This script is used to run the ansible-galaxy iridl installation.
# It will check for the existence of the virtual environment: /opt/datalib_venv3.12
#
# It will check for any local git changes that might need to be pushed, and it will check for
# any git changes that need to be pulled.
##
VENV=/opt/datalib_venv3.12
BUILD=""
CHECK=""
FETCH=1

function showhelp()
{
  echo "$0 [--build] [--check]"
  echo " --check:     Optional argument to check what will be done without making changes."
  echo " --build:     Optional argument to build or rebuild the maprooms.  This can take a long time."
  echo " --no-fetch:  Optional argument in case of a lack of internet connection. This will disable"
  echo "              the fetch from the remote git repository.  This should only be used if you are"
  echo "              completely sure that the remote repository hasn't changed, otherwise you could"
  echo "              end up reverting to an older version without features that were previously installed."
  echo ""
  exit
}

if [ $# -gt 0 ]; then
  case $1 in
    --build)
      BUILD="-e run_update_script=yes"
      ;;
    --check)
      CHECK="--check"
      ;;
    --no-fetch)
      FETCH=0
      ;;
    *)
      showhelp
      ;;
  esac
fi

# Check if the virtual environment exists
echo -n "checking python virtual environment..."
if [ -d "${VENV}" ]; then
  source "${VENV}/bin/activate"
  if [ $? != 0 ]; then
    echo ""
    echo "Couldn't activate Python environment ${VENV}"
    echo "Please review the documentation: https://dldocs.iri.columbia.edu/admin/server/centos9_stream.html#install_python"
    exit 1
  fi
fi
echo "ok"

# check for secrets.yaml file
if [ ! -f "../secrets.yaml" ]; then
  echo "../secrets.yaml file doesn't exist.  Please read the documentation on deploy keys and Configuring your Data Library:"
  echo "* https://dldocs.iri.columbia.edu/admin/git.html#deployment-keys"
  echo "* https://dldocs.iri.columbia.edu/admin/installation.html#configure-your-data-library-repository"
  echo ""
  exit 1
fi

# Check for git changes
echo "Checking for git changes"
if [[ ${FETCH} == 1 ]]; then
  git fetch
  if [ $? != 0 ]; then
    echo ""
    echo "git fetch has failed. We can not communicate with the GIT cloud repository.  There are"
    echo "several reasons this might happen: either you don't have an internet connection, or you"
    echo "don't have permission to access the repository.  Please insure that your account has access to the"
    echo "repository [ See: https://dldocs.iri.columbia.edu/admin/git.html ].  If your internet connection is offline"
    echo "and this is an urgent update, then you can rerun this command with the --no-fetch command.  This should"
    echo "only be done if you are positive that there are no changes on the server because this may revert the DL to"
    echo "an older version without features that were previously installed.  If you can wait, you should wait."
    echo ""
    exit 1
  fi
fi

gitstatus="$(git status)"
echo ""

behind="branch is behind \'origin"
if [[ "$gitstatus" =~ "$behind" ]]; then
  echo "** Your branch is behind the cloud repository. You must pull your changes first"
  echo "to insure you do not damage the Data Library."
  echo ""
  echo "Use: git pull --ff-only"
  echo ""
  exit 1
fi

echo ""
echo "If you have changes, you should commit them."
echo ""
echo "For more information, review https://dldocs.iri.columbia.edu/admin/maintenance.html"
echo ""

if [[ "${CHECK}" != "" ]]; then
  echo "You are running the command in check mode, no changes will be made."
else
  echo "You are about to apply changes to the Data Library installation."
fi
echo ""
read -p "Do you want to continue: (yes or no): " answer
if [[ "${answer}" != "yes" ]]; then
  exit 1
fi

ansible-playbook --ask-become-pass -i inventory.cfg -e @../secrets.yaml ${CHECK} ${BUILD} playbook.yaml