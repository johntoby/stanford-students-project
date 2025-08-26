# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  # Use Ubuntu 22.04 LTS
  config.vm.box = "ubuntu/jammy64"
  config.vm.box_check_update = false

  # Configure VM resources and VirtualBox settings
  config.vm.provider "virtualbox" do |vb|
    vb.name = "stanford-students-api"
    vb.memory = "2048"
    vb.cpus = 2
    vb.gui = false
    vb.customize ["modifyvm", :id, "--uart1", "0x3F8", "4"]
    vb.customize ["modifyvm", :id, "--uartmode1", "file", File::NULL]
  end

  # Network configuration - port forwarding only to avoid conflicts
  config.vm.network "forwarded_port", guest: 8080, host: 8080
  config.vm.network "forwarded_port", guest: 8081, host: 8081
  config.vm.network "forwarded_port", guest: 8082, host: 8082
  config.vm.network "forwarded_port", guest: 5432, host: 5432

  # Provision with inline script to avoid file sync issues
  config.vm.provision "shell", inline: <<-SHELL
    # Update system
    sudo apt update
    
    # Install Docker
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker vagrant
    
    # Install Docker Compose
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    
    # Install Make
    sudo apt install -y make git
    
    echo "Setup completed! SSH into VM and clone your project."
  SHELL

  # Set hostname
  config.vm.hostname = "stanford-api-vm"

  # Simplified SSH configuration
  config.ssh.insert_key = true
  config.ssh.forward_agent = false
  config.ssh.connect_timeout = 300
  config.vm.boot_timeout = 900
  
  # Disable synced folder temporarily to avoid boot issues
  config.vm.synced_folder ".", "/vagrant", disabled: true
  

end