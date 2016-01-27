# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure(2) do |config|
  # FIXME This is a third-party dependency (the NSA is watching!)
  config.vm.box = "ubuntu/trusty64"
  config.vm.network :private_network, ip: "192.168.11.22"
  config.vm.hostname = 'hubot.local'
  config.vm.provider "virtualbox" do |v|
    v.memory = 2048
  end
  config.vm.network "forwarded_port", guest: 8080, host: 8080

  # Provision the machine using an ansible playbook.
  # See documenation at:
  #  - http://docs.ansible.com/guide_vagrant.html
  #  - https://docs.vagrantup.com/v2/provisioning/ansible.html
  config.vm.provision "ansible" do |ansible|
    ansible.playbook = "#{ENV['playbook'] || 'site.yml'}"
    ansible.inventory_path = "#{ENV['inventory'] || 'vagrant-inventory'}"
    ansible.limit = 'all'  # The special 'all' group name.
    ansible.ask_vault_pass = true
    # ansible.verbose = 'vvv'
  end
end
