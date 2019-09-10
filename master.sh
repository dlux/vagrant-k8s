# !/bin/bash
# Description: Setup node as master node, add list of worker nodes
# Tasks:
#    - Install kubernetes cluster - master node
# Tested on OS: Centos7.6

set -o xtrace

pod_cidr='50.244.0.0/16'

pushd /opt
source common_packages
[[ "$?" != '0' ]] && echo 'Unable to get function packages' && exit 1
EnsureRoot
source .PROXY
WriteLog '<-- Master node setup'
cat <<EOF >  /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sysctl --system
lsmod | grep br_netfilter

WriteLog '<-- Downloading config images'
WriteLog "$(kubeadm config images pull)"
WriteLog '<-- Starting kubernetes master - Using private network ETH1'
_ip=$(ip addr show eth1 | grep inet|awk '{print $2}'|awk -F'/' '{print $1}')
WriteLog "$(kubeadm init --apiserver-advertise-address $_ip --pod-network-cidr=$pod_cidr)"

mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config

mkdir -p /home/vagrant/.kube
cp -i /etc/kubernetes/admin.conf /home/vagrant/.kube/config
chown -R vagrant:vagrant /home/vagrant/.kube

kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/a70459be0084506e4ec919aa1c114638878db11b/Documentation/kube-flannel.yml

pushd /vagrant
kubeadm token create --print-join-command > join_cmd

