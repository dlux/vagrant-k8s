# vagrant-k8s

[![Build Status](https://travis-ci.com/dlux/vagrant-k8s.svg?branch=master)](https://travis-ci.com/dlux/vagrant-k8s)

## Summary

Project is a Kubernetes development environment
Initial environment is created via kubeadm single master node and one worker

## Environment

- Vagrant
- virtualbox


| Name     | Role       |  Characteristics         |
|----------|------------|--------------------------|
| master   | k8s master | cpus:4, memory: 4Gb      |
| worker01 | k8s worker | cpus:1, memory: 2Gb      |


## To Run

- Install vagrant and virtualbox

    $ ./setup_localhost.sh -x http://proxy:port -p virtualbox

- Deploy environment

    $ vagrant up

## Troubleshooting

- After initial setup if there are issues with the VM follow troubleshoot file

