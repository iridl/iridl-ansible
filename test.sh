#!/bin/bash

cleanup() {
    # output to /dev/null to supress confusing message "Not logged in"
    # when script exits before completing the login step.
    docker logout > /dev/null
    [[ -n "$builddir" ]] && rm -rf $builddir
}

trap cleanup EXIT

fail() {
  echo $*
  exit 1
}

builddir=$(mktemp --tmpdir=/tmp --directory ansible-test.XXXXXXXXXX) || fail "failed to create build dir"
export ANSIBLE_COLLECTIONS_PATH=$builddir

ansible-galaxy collection install .
(cd $builddir/ansible_collections/iridl/iridl && ansible-test sanity --docker)
ansible-playbook -i test-inventory.yaml -e @test-vars-iri.yaml test.yaml
