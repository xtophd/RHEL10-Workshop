#!/bin/bash

RELOADER="$0"
echo "${RELOADER}"
echo "--------------------"

source ./xtoph-setup/xtoph-setup.shlib
source ./xtoph-setup/virthost-menu.shlib
source ./xtoph-setup/network-menu.shlib
source ./xtoph-setup/ansible-menu.shlib
source ./xtoph-setup/node-menu.shlib
source ./xtoph-setup/bastion-menu.shlib
source ./xtoph-setup/ldap-menu.shlib

# --

##
##    Variables unique to this Project
##

export PROJECT_NAME="r10demo"

export RHEL_VERSION="10.0"

export GIT_SHOWROOM_SOURCE="github.com/rhpds/showroom-lb1136-rhel-10-hol"
export GIT_SHOWROOM_BRANCH="development"

export WORKSHOP_ADMIN_UID="cloud-admin"
export WORKSHOP_ADMIN_PW

export WORKSHOP_STUDENT_UID="cloud-user"
export WORKSHOP_STUDENT_PW

export RHSM_USER_UID
export RHSM_USER_PW

##
##    ESTABLISH SOME ADDITIONAL DEFAULTS
##

NAME_NODE1="bastion"
NAME_NODE2="node1"
NAME_NODE3="node2"
NAME_NODE4="node3"
NAME_NODE5="node4"
NAME_NODE6="leapp"

NICMODE_NODE1="static"
NICMODE_NODE2="dhcp"
NICMODE_NODE3="dhcp"
NICMODE_NODE4="dhcp"
NICMODE_NODE5="dhcp"
NICMODE_NODE6="dhcp"

HGROUP_NODE1="myBastion"
HGROUP_NODE2="myNodes"
HGROUP_NODE3="myNodes"
HGROUP_NODE4="myNodes"
HGROUP_NODE5="myNodes"
HGROUP_NODE6="myLeapp"

##
##    Load current answer file
##

[[ -e ./config/rhel-workshop-setup.ans ]] && . ./config/rhel-workshop-setup.ans


# ---

rhel_dump () {

##
##    NOTE: don't save passwords 
##          user will always need 
##          to enter ALL of them
##

cat <<EOVARS

## RHEL SETTINGS

    PROJECT_NAME="${PROJECT_NAME}"

    RHEL_VERSION="${RHEL_VERSION}"

    GIT_SHOWROOM_SOURCE="${GIT_SHOWROOM_SOURCE}"
    GIT_SHOWROOM_BRANCH="${GIT_SHOWROOM_BRANCH}"

    WORKSHOP_ADMIN_UID="${WORKSHOP_ADMIN_UID}"
    # WORKSHOP_ADMIN_PW=""

    WORKSHOP_STUDENT_UID="${WORKSHOP_STUDENT_UID}"
    # WORKSHOP_STUDENT_PW=""

    RHSM_USER_UID="${RHSM_USER_UID}"
    # RHSM_USER_PW=""

EOVARS

}


# ---

save_settings () {

    ##
    ##    NOTE: don't save passwords 
    ##          user will always need 
    ##          to enter ALL of them
    ##

    ##
    ##    NOTE:  Network broadcast and netmask
    ##           are calculated from the prefix
    ##           and also not saved
    ##

    if [[ ! -z ${NETWORK_PREFIX} && ! -z ${NETWORK_ID} ]]; then
        NETWORK_BROADCAST=`ipcalc ${NETWORK_ID}/${NETWORK_PREFIX} -b | cut -d= -f2` 
        NETWORK_NETMASK=`ipcalc ${NETWORK_ID}/${NETWORK_PREFIX} -m | cut -d= -f2` 
    fi

    rhel_dump  > ./config/rhel-workshop-setup.ans
    ansible_dump  >> ./config/rhel-workshop-setup.ans
    virthost_dump >> ./config/rhel-workshop-setup.ans
    bastion_dump  >> ./config/rhel-workshop-setup.ans
    network_dump  >> ./config/rhel-workshop-setup.ans
    node_dump     >> ./config/rhel-workshop-setup.ans
    ldap_dump     >> ./config/rhel-workshop-setup.ans

}


# ---

rhel_settings () {

    ##
    ##    Network broadcast and netmask
    ##    are calculated from the prefix
    ##    and also not saved
    ##

    if [[ ! -z ${NETWORK_PREFIX} && ! -z ${NETWORK_ID} ]]; then
        NETWORK_BROADCAST=`ipcalc ${NETWORK_ID}/${NETWORK_PREFIX} -b | cut -d= -f2` 
        NETWORK_NETMASK=`ipcalc ${NETWORK_ID}/${NETWORK_PREFIX} -m | cut -d= -f2` 
    fi

    ##
    ##    Bash Lesson:  the bash shell parameter expansion ':+' passes
    ##                  expansion if paramenter is set and not null
    ##                  we use this to mask passwords for example
    ##

    echo ""
    echo "Project Name ... ${PROJECT_NAME}"
    echo ""

    echo "[ RHEL ]"
    echo "    Version          ... ${RHEL_VERSION}"
    echo "    Workshop Admin   ... ${WORKSHOP_ADMIN_UID} / ${WORKSHOP_ADMIN_PW:+**********}" 
    echo "    Workshop Student ... ${WORKSHOP_USER_UID} / ${WORKSHOP_USER_PW:+**********}" 
    echo "    RHSM User        ... ${RHSM_USER_UID} / ${RHSM_USER_PW:+**********}" 
    echo "    BMC Defaults     ... ${BMC_UID_DEFAULT} / ${BMC_PW_DEFAULT:+**********}" 
}


# ---


current_settings () {
    rhel_settings
    ansible_settings
    network_settings
    ldap_settings
    bastion_settings
    virthost_settings
    node_settings
 }


# ---


rhel_bulk_edit () {

    TMPFILE="$(mktemp /var/tmp/ocp-workshop-setup.XXXXX)"

    rhel_dump > $TMPFILE

    vi $TMPFILE

    read -p "Accept BULK EDIT update (Y/N)? " input

    if [[ "${input^^}" == "Y" ]]; then
      source $TMPFILE
      echo "Changes sourced..."
    fi

    rm $TMPFILE

}


# ---


prepare_deployment () {

    echo ""

    echo "## Install Ansible from ${ANSIBLE_SOURCE}"

    case ${ANSIBLE_SOURCE} in 

      "RHSM") 
        ./sample-scripts/rhel9-install-ansible-rhsm.sh 
        ;;

      "EPEL") 
        ./sample-scripts/rhel9-install-ansible-epel.sh 
        ;;
    
      "INSTALLED") 
        echo " - success (ansible already installed)"
        ;;

      "*" )
        echo "WARNING: you must set a valid ansible source"
        return 1
        ;;
    esac

    ##
    ##    Reprint the current settings & re-calculate any vars
    ##      (ipcalc may have just gotten installed)
    ##

    echo -n "## Here are the current settings"

    current_settings



    echo -n "## Templating configuration files"

    ansible-playbook sample-configs/rhel-workshop-setup.yml




    echo -n "## Encrypt the credentials.yml"

    if [[ -z "${ANSIBLE_VAULT_PW}" ]]; then
      echo " - FAILED" 
      echo "WARNING: you must set the ANSIBLE_VAULT_PW"
      return 1
    else
      echo "${ANSIBLE_VAULT_PW}" > ./config/vault-pw.tmp
      ansible-vault encrypt --vault-password-file ./config/vault-pw.tmp config/credentials.yml 1>/dev/null 2>&1

      if [[ $? ]] ; then
        rm -f ./config/vault-pw.tmp
        echo " - success" 
      else
        rm -f ./config/vault-pw.tmp
        echo " - FAILED" 
        return 1
      fi
    fi

}

# ---

rhel_menu () {

    SAVED_PROMPT="$PS3"

    PS3="CLUSTER MENU: "

    echo ""
    rhel_settings
    echo ""

    select action in "RETURN to previous menu" "BULK EDIT params" "Set Version" "Set Workshop Admin UID/PW" "Set Workshop Student UID/PW" "Set RHSM UID/PW" "Set Default BMC UID/PW"
    do
      case ${action}  in

        "BULK EDIT params")
          rhel_bulk_edit
          ;;

        "Set Version")
           select RHEL_VERSION in "10.1" "10.0" "10.beta"
           do
              case ${RHEL_VERSION} in
                "10.1" |  \
                "10.0" |  \
                "10.beta" )
                  break ;;

                "*" )
                  ;;
              esac
              REPLY=
            done
          ;;

        "Set Workshop Admin UID/PW")
          set_uidpw "Workshop Admin" "WORKSHOP_ADMIN_UID" "WORKSHOP_ADMIN_PW"
          ;;

        "Set Workshop Student UID/PW")
          set_uidpw "Workshop User"  "WORKSHOP_STUDENT_UID"  "WORKSHOP_STUDENT_PW"
          ;;

        "Set RHSM UID/PW")
          set_uidpw "Workshop User"  "RHSM_USER_UID"      "RHSM_USER_PW"
          ;;

        "Set Default BMC UID/PW")
          set_uidpw "BMC Default"    "BMC_UID_DEFAULT"    "BMC_PW_DEFAULT"
          ;;

        "RETURN to previous menu")
          PS3=${SAVED_PROMPT}
          break
          ;;

        "*")
          echo "That's NOT an option, try again..."
          ;;

      esac

      ##
      ##    Reprint the current settings
      ##

      echo ""
      rhel_settings
      echo ""

      ##
      ##    The following causes the select
      ##    statement to reprint the menu
      ##

      REPLY=

    done

}

# ---

main_menu () {

    PS3="MAIN MENU (select action): "

    echo ""
    current_settings
    echo ""

    select action in "PREPARE Deployment" \
                     "Set Project Name" \
                     "RHEL Settings" \
                     "Ansible Settings" \
                     "Network Settings" \
                     "LDAP Settings" \
                     "Bastion Settings" \
                     "Virt Host Settings" \
                     "Node Settings" \
                     "SAVE Current Params" \
                     "RELOAD Saved Params"

    do
      case ${action}  in

        "Set Project Name")
          set_key "Enter Project Name" "PROJECT_NAME"
          ;;

        "Ansible Settings")
          ansible_menu
          ;;

        "LDAP Settings")
          ldap_menu
          ;;

        "Bastion Settings")
          bastion_menu
          ;;

        "RHEL Settings")
          rhel_menu
          ;;

        "Network Settings")
          network_menu
          ;;

        "Virt Host Settings")
          virthost_menu
          ;;

        "Node Settings")
          node_menu
          ;;

        "PREPARE Deployment")
          save_settings
          prepare_deployment
          ;;

        "SAVE Current Params")
          save_settings
          ;;

        "RELOAD Saved Params")
          exec "${RELOADER}"
          break
          ;;

        "*")
          echo "That's NOT an option, try again..."
          ;;       
 
      esac

      ##
      ##    Reprint the current settings
      ##

      echo ""
      current_settings
      echo ""

      ##
      ##    The following causes the select
      ##    statement to reprint the menu
      ##

      REPLY=

    done

}


##
##    Testing for 'ansible-playbook' command
##

[[ -x `which ansible-playbook` ]] && ANSIBLE_SOURCE="INSTALLED"


##
##    Engage the main_menu
##

main_menu

