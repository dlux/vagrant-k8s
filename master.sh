# !/bin/bash
# Description: Setup node as master node, add list of worker nodes
# Tasks:
#    - Install kubernetes cluster - master node
# Tested on OS: Centos7.6

set -o xtrace

pod_cidr='150.244.0.0/16'

pushd /opt
[[ ! -f common_packages ]] && echo 'no proxy file' && exit 1
source common_packages
[[ "$?" != '0' ]] && echo 'Unable to get function packages' && exit 1
EnsureRoot
source .PROXY
WriteLog '<-- Master node setup'
WriteLog '<-- Update iptables'
cat <<EOF >  /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sysctl --system
[[ -z $(lsmod | grep br_netfilter) ]] && modprobe br_netfilter

WriteLog '<-- Downloading config images'
kubeadm config images pull

WriteLog '<-- Starting kubernetes master - Using private network ETH1'
_ip=$(ip addr show eth1 | grep inet|awk '{print $2}'|awk -F'/' '{print $1}')
kubeadm init --apiserver-advertise-address $_ip --pod-network-cidr=$pod_cidr
sleep 15
mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config
mkdir -p /home/vagrant/.kube
cp -i /etc/kubernetes/admin.conf /home/vagrant/.kube/config
chown -R vagrant:vagrant /home/vagrant/.kube

WriteLog '<-- Configuring Calico CNI'
calico_add='https://docs.projectcalico.org/latest'
base="$(curl -s $calico_add | grep location | awk -F '"' '{print $2}')"
kubectl apply -f ${base}manifests/calico.yaml
sleep 15

kubectl get nodes
WriteLog "$(kubectl get nodes)"

pushd /vagrant
kubeadm token create --print-join-command > join_cmd

