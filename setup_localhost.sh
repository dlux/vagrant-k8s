#!/bin/bash

# Description: Install and setup vagrant and [virtualbox or libvirt]

# Tasks:
#    - Install vagrant
#    - Install vagrant hypervisor provider either virtualbox or libvirt
# Optional Parameters:
#    -x proxy
#    -p provider
# Tested on OS: Centos7.6

set -o xtrace
xtrace
_PROVIDER='libvirt'

# If proxy passed as parameter
while [[ ${1} ]]; do
    case "$1" in
    --proxy|-x)
        [[ -z "${2}" || "${2}" == -* ]] && echo 'Missing proxy' && exit 1
        x="-x $2"
        _PROXY="$2"
        shift ;;
    --provider|-p)
        [[ -z "${2}" || "${2}" == -* ]] && echo 'Missing provider' && exit 1
        _PROVIDER=$(echo "$2" |tr '[:upper:]' '[:lower:]')
        shift ;;
    *)
        usage="Usage \n $(basename "$0"): "
        echo -e "$usage [-x http://proxy:port] | [-p [virtualbox | libvirt] ]"
        exit 0
    esac
    shift
done

curl $x -LO https://github.com/dlux/InstallScripts/raw/master/common_functions
curl $x -LO https://github.com/dlux/InstallScripts/raw/master/common_packages
source common_packages
WriteLog "Setting up localhost with vagrant and provider $_PROVIDER"
EnsureRoot
[[ -n "$_PROXY" ]] && SetProxy "$_PROXY"

InstallVagrant

if "$_PROVIDER" == "libvirt"; then
    InstallLibvirt
    vagrant plugin install vagrant-libvirt
else
    InstallVirtualBox
fi

