# !/bin/bash
# Description: Setup node as master node, add list of worker nodes
# Tasks:
#    - Install kubernetes cluster - master node
# Tested on OS: Centos7.6

set -o xtrace

pod_cidr='150.244.0.0/16'
service_cidr='150.200.0.0/16'
service_dns_ip='150.200.0.10'

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
kubeadm init \
    --apiserver-advertise-address $_ip \
    --pod-network-cidr=$pod_cidr \
    --service-cidr=$service_cidr \
    -v 9 2>&1 | tee -a k8s_install.log
sleep 30

mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config
mkdir -p /home/vagrant/.kube
cp -i /etc/kubernetes/admin.conf /home/vagrant/.kube/config
chown -R vagrant:vagrant /home/vagrant/.kube

WriteLog '<-- Configuring Calico - Kubernetes API datastore—50 nodes or less'
WriteLog '<-- Calico for policy and networking'
# https://docs.projectcalico.org/v3.9/
#          getting-started/kubernetes/installation/calico
# See instruction for etcd data store on above url
calico_add='https://docs.projectcalico.org/latest'
base="$(curl -s $calico_add | grep location | awk -F '"' '{print $2}')"
curl -LO ${base}manifests/calico.yaml
sed -i "s\\192.168.0.0.16\\${pod_cidr}\\g" ./calico.yaml
kubectl apply -f ./calico.yaml
# Attempt 5 times (wait 1 min for master node to be ready)
i=0
while [ $i -lt 5 ]
do
    ready=$(kubectl get nodes | tail -n1 | grep -i noready)
    [[ -z $ready ]] && break || sleep 15
done

WriteLog "<-- Installing Calico CLI - API datastore"
kubectl apply -f ${base}manifests/calicoctl.yaml


WriteLog "<-- Copying join command"
pushd /vagrant
kubeadm token create --print-join-command > join_cmd

WriteLog "<-- Removing taints from  master so that pods can be schedule on it"
WriteLog "$(kubectl describe node master | taint)"
kubectl taint nodes --all node-role.kubernetes.io/master-
WriteLog "$(kubectl describe node master | taint)"

# Cluster Verification
kubectl get nodes
WriteLog "$(kubectl get nodes)"
WriteLog "$(kubectl get -A pods -o wide)"

