# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  # Use Ubuntu 24.04 LTS
  config.vm.box = "ubuntu/jammy64"
  config.vm.box_version = "20241002.0.0"

  # Configure VM resources
  config.vm.provider "virtualbox" do |vb|
    vb.name = "stanford-students-api"
    vb.memory = "2048"
    vb.cpus = 2
  end

  # Network configuration - forward ports
  config.vm.network "forwarded_port", guest: 8080, host: 8080, host_ip: "127.0.0.1"
  config.vm.network "forwarded_port", guest: 8081, host: 8081, host_ip: "127.0.0.1"
  config.vm.network "forwarded_port", guest: 8082, host: 8082, host_ip: "127.0.0.1"
  config.vm.network "forwarded_port", guest: 5432, host: 5432, host_ip: "127.0.0.1"

  # Sync project folder
  config.vm.synced_folder ".", "/home/vagrant/stanford-students-project", 
    owner: "vagrant", group: "vagrant"

  # Provision with installation script
  config.vm.provision "shell", path: "vagrant-setup.sh", privileged: false

  # Set hostname
  config.vm.hostname = "stanford-api-vm"

  # SSH configuration
  config.ssh.forward_agent = true
  config.ssh.insert_key = false
end