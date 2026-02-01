Vagrant.configure("2") do |config|
  # Change box to Ubuntu 16.04
  config.vm.box = "bento/ubuntu-16.04"
  
  config.vm.network "public_network"

  # FIX: Disable default mount and use rsync instead
  config.vm.synced_folder ".", "/vagrant", type: "rsync", rsync__exclude: [".git/", ".vagrant/"]
  
  config.vm.provider "virtualbox" do |v|
    v.memory = 4096
    v.cpus = 2
    # This makes the CPU appear more "generic" to the guest
    v.customize ["modifyvm", :id, "--cpu-profile", "host"]
  end

  # Provisioning: Ensure Ansible is installed on the guest
  # Ubuntu 16.04 needs specific repos for modern Ansible versions
  config.vm.provision "shell", inline: <<-SHELL
    export DEBIAN_FRONTEND=noninteractive
    echo 'Defaults:vagrant !requiretty' | sudo tee /etc/sudoers.d/vagrant-nopty
    echo 'vagrant ALL=(ALL) NOPASSWD:ALL' | sudo tee /etc/sudoers.d/vagrant-nopasswd
    sudo chmod 0440 /etc/sudoers.d/vagrant-nopty
    sudo chmod 0440 /etc/sudoers.d/vagrant-nopasswd

    # Install Ansible if not present
    if ! command -v ansible >/dev/null; then
      sudo apt-get update
      sudo apt-get install -y software-properties-common
      sudo apt-add-repository -y ppa:ansible/ansible
      sudo apt-get update
      sudo apt-get install -y ansible
    fi
  SHELL

  # Provisioning Wordpress
  config.vm.provision "ansible_local" do |ansible|
    ansible.become = true
    ansible.become_user = "root"
    ansible.compatibility_mode = "2.0"
    ansible.playbook = "infrastructure/ansible/wordpress.yml"
    ansible.inventory_path = "infrastructure/ansible/inventory.ini"
    # Note: Ubuntu 16.04 hostnames vary; 'all' is safer than a specific limit 
    # unless your inventory.ini specifically defines localhost.localdomain
    ansible.limit = "all" 
  end

end
