# encoding : utf-8
# -*- mode: ruby -*-
# vi: set ft=ruby :
Vagrant.configure("2") do |config|

  config.vm.box = "ubuntu/jammy64"
  config.vm.box_check_update = false

  config.vbguest.auto_update = true
  config.vbguest.no_remote = true

  config.ssh.insert_key = false

  config.vm.hostname = "ubuntu22-docker"

  config.vm.network "private_network", ip: "192.168.33.13"
  #config.vm.network "public_network"

  config.vm.synced_folder "./sync", "/home/vagrant/sync", type: "virtualbox", mount_options: ["dmode=775,fmode=775"]

  config.vm.provider "virtualbox" do |vb|
    vb.name = "ubuntu22-docker"
    vb.gui = false
    vb.cpus = "4"
    vb.memory = "3072"
    vb.customize ["modifyvm", :id, "--vram", "32", "--clipboard", "bidirectional", "--draganddrop", "bidirectional"]
  end

end
