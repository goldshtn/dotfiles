#!/bin/bash
#
# USAGE:    provision.sh [--workshop]
#
# Pass in --workshop to provision the full workshop environment, with Node,
# MySQL, PostgreSQL etc. Otherwise, only a basic development environment
# with BCC is provisioned.

export LANG="en_US.utf8"
export LANGUAGE="en_US.utf8"
export LC_ALL="en_US.utf8"

if [[ "$1" == "--workshop" ]]; then
    export WORKSHOP=1
fi

vagrant up
vagrant ssh -c 'screen -RR -D'
