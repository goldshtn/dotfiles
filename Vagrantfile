# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "bento/fedora-25"
  config.vm.box_check_update = false

  # config.vm.network "forwarded_port", guest: 80, host: 8080
  config.vm.synced_folder ".", "/setup"

  config.vm.provider "virtualbox" do |vb|
    vb.memory = "2048"
    vb.cpus = 2
  end

  config.vm.provision "shell", privileged: false, inline: <<-SHELL
    export WORKSHOP=#{ENV['WORKSHOP']}
    if [[ "$WORKSHOP" == "1" ]]; then echo "Provisioning in workshop mode"; fi
    /setup/install.sh
  SHELL
end
