# -*- mode: ruby -*-
# vi: set ft=ruby :

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
Vagrant.configure("2") do |config|
  # Every Vagrant development environment requires a box. You can search for
  # boxes at https://vagrantcloud.com/search.
  # config.vm.box = "ubuntu/xenial64"
  config.vm.box = 'generic/centos7'
  config.vm.box_version = '1.9.2'
  config.vm.synced_folder './', '/vagrant'

  config.vm.provision "shell" do |s|
    s.path = 'common.sh'
    s.args = ENV['http_proxy']
  end

  config.vm.define "master" do |master|
    master.vm.hostname = 'master'
    # Make this network our main public network - 20.0.2.0/16
    master.vm.network "private_network", ip: '20.0.2.15'
    master.vm.network :forwarded_port, guest: 6443, host: 6443
    master.vm.network :forwarded_port, guest: 8080, host: 8080
    config.vm.provider 'virtualbox' do |v|
      v.customize ['modifyvm', :id, '--memory', 1024 * 4]
      v.customize ['modifyvm', :id, '--cpus', 4]
      # To ignore NAT IP - use a different subnet
      v.customize ["modifyvm", :id, "--natnet1", "110.0.2.0/24"]
    end

    master.vm.provision "shell" do |s|
      s.path = 'master.sh'
    end
  end

  config.vm.define "worker" do |worker|
    worker.vm.hostname = 'worker01'
    worker.vm.network "private_network", ip: '20.0.2.16'
    config.vm.provider 'virtualbox' do |v|
      v.customize ['modifyvm', :id, '--memory', 1024 * 2]
      v.customize ['modifyvm', :id, '--cpus', 1]
      # To ignore NAT IP - use a different subnet
      v.customize ["modifyvm", :id, "--natnet1", "110.0.2.0/24"]
    end
    worker.vm.provision "shell" do |s|
      s.path = 'worker.sh'
    end
  end
end
