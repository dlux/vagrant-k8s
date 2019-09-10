# !/bin/bash
# Description: Join node as worker of given master node
# $1 - Master ip address
# Tested on OS: Centos7.6

set -o xtrace

pushd /opt
source common_packages
[[ "$?" != '0' ]] && echo 'Unable to get function packages' && exit 1
EnsureRoot
source .PROXY

WriteLog '<-- Join node'
# kubeadm join $192.168.0.10:6443 --token $token --ca

pushd /vagrant
$(cat join_cmd)

