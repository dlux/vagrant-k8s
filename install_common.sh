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

pod_cidr='50.244.0.0/16'

# If proxy passed as parameter
[[ -n "$1" ]] && x="-x $1" && http_proxy="$1"

pushd /opt

curl $x -LO https://github.com/dlux/InstallScripts/raw/master/common_functions
curl $x -LO https://github.com/dlux/InstallScripts/raw/master/common_packages
source common_packages
[[ "$?" != '0' ]] && echo 'Unable to get function packages' && exit 1

WriteLog "Installing K8S dependencies"
EnsureRoot
swapoff -a

if [ -n "$http_proxy" ]; then
    _DOMAIN="$_DOMAIN,50.244.0.0/16"
    SetProxy "$http_proxy"
fi

UpdatePackageManager
$_INSTALLER_CMD vim screen git

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

WriteLog 'Installing kubernetes'
sudo bash -c 'cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
exclude=kube*
EOF'

DisableFirewalld
DisableSelinux
yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
systemctl enable kubelet && systemctl start kubelet

