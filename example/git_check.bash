#!/bin/bash
#
# Script to give some information to the user about their status in git and whether they should continue
# running the ansible playbook or not.
#

# In some cases, the master branch may be called something else...
MASTER_BRANCH="$(git remote show origin | sed -n '/HEAD branch/s/.*: //p')"
REMOTE_BRANCH="origin/${MASTER_BRANCH}"
CURRENT_BRANCH="$(git rev-parse --abbrev-ref HEAD)"

function showhelp() {
  echo "$0 [--master master_branch_name]"
  echo "  --master:  By default, this script assumes the master branch is named master"
  echo "             If this is not the master branch name, provide the actual master branch name"
  echo "             used for this repository."
  exit 1
}

while (( $# )); do
  case $1 in
    --master)
      shift
      MASTER_BRANCH=$1
      shift
      ;;
    *)
      showhelp
      ;;
  esac
  shift
done

_fetch() {
  git fetch
  if [ $? != 0 ]; then
    echo ""
    echo "git fetch has failed. We can not communicate with the GIT cloud repository.  There are"
    echo "several reasons this might happen: either you don't have an internet connection, or you"
    echo "don't have permission to access the repository.  Please insure that your account has access to the"
    echo "repository [ See: https://dldocs.iri.columbia.edu/admin/git.html ].  If your internet connection is offline"
    echo "and this is an urgent update, then you can continue.  This should only be done if you are positive there are"
    echo "no changes on the server because this may revert the DL to an older version without features that were "
    echo "previously installed."
    echo "If you can wait, you should wait."
    echo ""
    return 1
  fi
  return 0
}

_check_master() {
  # determine if our current branch is not the master
  if [[ "${CURRENT_BRANCH}" != "${MASTER_BRANCH}" ]]; then
    echo ""
    echo "You are not currently working in the ${MASTER_BRANCH} branch of the git repository.  This is likely"
    echo "an error and you should probably be using the ${MASTER_BRANCH} branch of the repository before"
    echo "applying changes. For example:"
    echo "  git checkout  ${MASTER_BRANCH}"
    echo ""
    return 1
  fi
  return 0
}

_check_behind_master() {
  # check if our repo is behind the master.
  differences="$(git diff --exit-code ${REMOTE_BRANCH}..HEAD)"
  if [ $? != 0 ]; then
    echo "Your current branch is behind the ${REMOTE_BRANCH}. You should not apply any changes until you have pulled"
    echo "the changes. For example:"
    echo "  git pull --ff-only"
    echo ""
    git status
    return 1
  fi
  return 0
}

_check_commits_not_pushed() {
  differences="$(git log --exit-code ${REMOTE_BRANCH}..HEAD)"
  if [ $? != 0 ]; then
    echo ""
    echo "Your current branch has commits not applied to the master.  While this is not an error, you should make sure"
    echo "your changes do not conflict with the master by pushing your changes if you believe them to be complete"
    echo "and correct."
    echo ""
    echo $differences
    return 1
  fi
  return 0
}

echo -n "Testing access to the remote repository."
if _fetch; then
  echo " ok"
  echo ""
  # MUST be able to fetch before doing anything else

  # If we're not on the master branch, then don't continue
  if _check_master; then
    commits=_check_commits_not_pushed
    behind=_check_behind_master

    if [[ ${commits} && ${behind} ]]; then
      echo ""
      echo "You have changes both locally and on the remote.  This can be a problem if your local changes conflict"
      echo "with the remote version.  You will need to first pull the changes from the remote version before pushing"
      echo "your local changes.  For example: "
      echo "  git pull --ff-only"
      echo ""
      echo "If there are no conflicts, you can then push your changes to the remote. For example:"
      echo "  git push"
      echo ""
      echo "If there are conflicts, you can follow these instructions to resolve your conflicts: "
      echo "   https://support.atlassian.com/bitbucket-cloud/docs/resolve-merge-conflicts/"
      echo ""
      echo "Do not continue until everything is resolved and the output of 'git status' looks correct."
      echo ""
    fi
  fi
else
  echo ""
fi
echo ""
