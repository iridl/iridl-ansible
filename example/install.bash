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
CHECK="-diff"

function showhelp()
{
  echo "$0 [--build] [--check]"
  echo " --check:    Optional argument to check what will be done without making changes."
  echo " --build:    Optional argument to build or rebuild the maprooms.  This can take a long time."
  echo ""
  exit
}

if [ $# -gt 0 ]; then
  case $1 in
    --build|-build|build)
      BUILD="-e run_update_script=yes"
      ;;
    --check|-check|check)
      CHECK="--check --diff"
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
git fetch
git status
echo ""
echo "If your branch is behind the master repository, you should pull your changes first."
echo "If you have changes, you should commit them when after you have insured they work."
echo ""
echo "For more information, review https://dldocs.iri.columbia.edu/admin/maintenance.html"
echo ""

if [[ "${CHECK}" == "" ]]; then
  echo "You are running the command in check mode, no changes will be made."
else
  echo "You are about to make install your changes to the Data Library installation."
fi
echo ""
read -p "Do you want to continue: (yes or no) (default is no): " answer
if [[ "${answer}" != "yes" ]]; then
  exit 1
fi

ansible-playbook --ask-become-pass -i inventory.cfg -e @../secrets.yaml ${CHECK} ${BUILD} playbook.yaml