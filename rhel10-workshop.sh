#!/bin/bash

## This script is intended to be run:
##     on the control host (ie: bastion)
##     CWD =  ~root/RHEL10-Workshop




##
## Need to install ansible-core and rhel-system-roles
##

packages=""

if ! `rpm -qi ansible-core > /dev/null` ; then
    packages="$packages ansible-core"
fi

if ! `rpm -qi rhel-system-roles > /dev/null` ; then
    packages="$packages rhel-system-roles"
fi

if [[ ${#packages} > 0 ]] ; then

    echo "Attempting to install missing ansible components..."
    dnf install -y $packages || exit;

fi

##
##
##

myInventory="./config/master-config.yml"
myCredentials="./config/credentials.yml"

if [ ! -e "${myInventory}" ] ; then
    echo "ERROR: Are you in the right directory? Can not find ${myInventory}" ; exit
    exit
fi

if [ -e "${myCredentials}" ] ; then
    askVaultPass="--ask-vault-pass"
else
    askVaultPass=""
fi
    
    
case "$1" in
    "all")
        time  ansible-playbook ${askVaultPass} -i ${myInventory} ./playbooks/rhel10-workshop.yml
        ;;

    "debug"       | \
    "bastion"     | \
    "dnf"         | \
    "boom"        | \
    "bootc"       | \
    "buildah"     | \
    "ebpf"        | \
    "firewalld"   | \
    "nftables"    | \
    "leapp"       | \
    "lightspeed"  | \
    "prep"        | \
    "podman"      | \
    "settings"    | \
    "stratis"     | \
    "systemd"     | \
    "tlog"        | \
    "virt"        | \
    "osbuild"     | \
    "vdo"         | \
    "wayland"     | \
    "webconsole"  | \
    "kpatch")

        time  ansible-playbook  ${askVaultPass} -i ${myInventory} --tags $1 ./playbooks/rhel10-workshop.yml
        ;;

    *)
        echo "USAGE: rhel10-workshop [ all | debug | bastion | prep | dnf | boom | bootc | buildah | ebpf | firewalld | nftables | leapp | osbuild | podman | settings | stratis | systemd | tlog | virt | vdo | wayland | webconsole | kpatch ]"
        ;;

esac

