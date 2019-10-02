# !/bin/bash
# Description: Setup common sw tp spin kubernetes cluster [master | worker]
# Tasks:
#    - Setup proxy on vagrant vm
#    - Install docker
#    - Configure proxy for docker
#    - Install kubectl cli
#    - Install kubeadm
#    - $1 => Proxy - http://proxy:port
# Tested on OS: Centos7.6

set -o xtrace

internal_cidr='20.0.0.0/8'
pod_cidr='150.244.0.0/16'
service_cidr='150.200.0.0/16'
service_dns_ip='150.200.0.10'
interface='eth1'

# If proxy passed as parameter
[[ -n "$1" ]] && x="-x $1"

pushd /opt

curl $x -LO https://github.com/dlux/InstallScripts/raw/master/common_functions
curl $x -LO https://github.com/dlux/InstallScripts/raw/master/common_packages
source common_packages
[[ "$?" != '0' ]] && echo 'Unable to get function packages' && exit 1

EnsureRoot

if [ -n "$1" ]; then
    WriteLog "Setting proxy for the system $1"
    _DOMAIN="$_DOMAIN,$pod_cidr,$service_cidr,$internal_cidr"
    SetProxy "$1"
fi

WriteLog "Updating the system"
swapoff -a
UpdatePackageManager
$_INSTALLER_CMD vim screen tmux yum-utils device-mapper-persistent-data lvm2
DisableFirewalld
DisableSelinux


WriteLog "Installing Docker"
InstallDocker
[[ -n "$http_proxy" ]] && SetDockerProxy "$http_proxy"
[[ -z $(command -v docker) ]] && PrintError 'Docker not installed'

WriteLog 'Setup docker daemon with systemd'
cat > /etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2",
  "storage-opts": [
    "overlay2.override_kernel_check=true"
  ]
}
EOF
mkdir -p /etc/systemd/system/docker.service.d
systemctl daemon-reload
systemctl restart docker


WriteLog 'Installing kubectl kubelet and kubeadm'
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
exclude=kube*
EOF

yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
systemctl enable kubelet
systemctl start kubelet

WriteLog "Injecting the correct node ip into kubelet:"
_ip=$(ip addr show $interface | grep inet | \
      awk '{print $2}'|awk -F'/' '{print $1}')

#https://github.com/kubernetes/kubeadm/issues/203
sed -i "s\\KUBELET_EXTRA_ARGS=\\KUBELET_EXTRA_ARGS=--node-ip=$_ip\\g"  /etc/sysconfig/kubelet
systemctl daemon-reload
systemctl start kubelet

