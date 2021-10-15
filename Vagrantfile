# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "centos/7"
  config.vm.box_version = "1811.02"
  config.vm.box_check_update = false
  config.ssh.insert_key = false

  config.vm.define "dlserver1", primary: true do |x|
    x.vm.network "forwarded_port", guest: 22, host: 2230 # must match ansible_port in inventory
    x.vm.network "forwarded_port", guest: 80, host: 8090 # must match dl_hostname in inventory
    x.vm.provider :virtualbox do |vb|
      vb.memory = 3 * 1024
    end
  end
end
