# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure(2) do |config|

  config.vm.box = "ubuntu/trusty64"

  # Run the bootstrap script
  config.vm.provision :shell, path: "bootstrap.sh", run: "once"
  config.vm.provision :shell, path: "startup.sh", run: "always", privileged: false

  # Forward the regulations-core for API browsing
  config.vm.network :forwarded_port, host: 8000, guest: 8000

  # Forward the regulations-site
  config.vm.network :forwarded_port, host: 8001, guest: 8001

  config.vm.provider "virtualbox" do |vb|
    vb.memory = 1024
  end
end

