#!/bin/bash

function die {
	echo >&2 "$@"
	exit 1
}

sudo dnf install -y curl

function upgrade_kernel {
    read -p "Your kernel is too old. Upgrade to latest mainline? [y/N] " -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    else
        curl -s https://repos.fedorapeople.org/repos/thl/kernel-vanilla.repo | sudo tee /etc/yum.repos.d/kernel-vanilla.repo
        sudo dnf --enablerepo=kernel-vanilla-mainline update -y
        exit 1
    fi
}

echo "Checking BPF config flags..."
for flag in CONFIG_BPF CONFIG_BPF_SYSCALL CONFIG_BPF_JIT CONFIG_BPF_EVENTS; do
    sysver=$(uname -r)
    present=`sudo cat /boot/config-$sysver | grep $flag= | cut -d= -f2`
    [[ "$present" = "y" ]] || die "$flag must be set"
done

echo "Checking if this version of Linux is supported..."
(uname -r | grep "fc2[45]" -q) || \
    die "Unsupported Linux version, only Fedora 24/25 is currently supported"

echo "Checking if this version of the kernel is supported..."
[[ $(uname -r) =~ ^([0-9]+)\.([0-9]+) ]]
majver=${BASH_REMATCH[1]}
minver=${BASH_REMATCH[2]}
if [[ "$majver" -lt "4" ]]
    then upgrade_kernel
fi
if [[ "$majver" -eq "4" && "$minver" -lt "9" ]]
    then upgrade_kernel
fi
