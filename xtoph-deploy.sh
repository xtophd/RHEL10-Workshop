#!/bin/bash

##
## NOTE: you must point to the correct inventory and extravars yml
##
##   Take a sample configs from ./sample-configs and 
##   copy them to ./playbooks/config
##

myInventory="./config/master-config.yml"

if [[ ! -e "${myInventory}" || ! -e "./xtoph-deploy.yml" ]] ; then
    echo "ERROR: Are you in the right directory? Can not find ${myInventory} | xtoph-deploy.yml" ; exit
    exit
fi

##
##
##

if [[ $2 != "" ]]; then

    echo "Ansible limit set to: $2"

    myLimits="-l $2"

else

    myLimits=""

fi

case "$1" in

    "deploy"     | \
    "finish"     | \
    "undeploy"   | \
    "redeploy"   | \
    "workshop"   | \
    "setup+"     | \
    "setup")

        time  ansible-playbook --ask-vault-pass -i ${myInventory} -f 10 -e xtoph_deploy_cmd=${1} ${myLimits} xtoph-deploy.yml
        ;;

    "git-updates")

        git pull
        ( cd ./roles/xtoph_deploy; pwd ; git pull )
        ( cd ./xtoph-setup; pwd ; git pull )
        ( cd ./hol-rhel10-showroom; pwd ; git pull )
        ;;

    *)
        echo "USAGE: xtoph-deploy.sh [ setup | setup+ | deploy | finish | undeploy | redeploy | workshop ]"
        echo ""
        echo "  setup     ... runs only 'setup' plays"
        echo "  setup+    ... runs both 'setup' and 'deploy' plays"
        echo "  deploy    ... runs only 'deploy' plays"
        echo "  finish    ... runs only 'finish' plays"
        echo "  undeploy  ... runs only 'undeploy' plays"
        echo "  redeploy  ... runs both 'undeploy' and 'deploy' plays"
        echo "  workshop  ... runs only the 'workshop' plays" 
        ;;

esac         
