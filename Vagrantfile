Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-16.04"

  config.vm.provider "virtualbox" do |v|
    v.memory = 2048
    v.cpus = 2
    v.linked_clone = true

    v.customize ["modifyvm", :id, "--paravirtprovider", "kvm"]
    v.customize ["modifyvm", :id, "--nested-paging", "off"]
    v.customize ["modifyvm", :id, "--vtxvpid", "off"]
    v.customize ["modifyvm", :id, "--uartmode1", "disconnected"]
    v.customize ["modifyvm", :id, "--nictype1", "virtio"]
  end

  config.vm.boot_timeout = 600
  config.ssh.insert_key = false # Prevents the SSH key replacement cycle from failing

  config.vm.provision "shell", inline: <<-SHELL
    export DEBIAN_FRONTEND=noninteractive
    echo 'Defaults:vagrant !requiretty' | sudo tee /etc/sudoers.d/vagrant-nopty
    echo 'vagrant ALL=(ALL) NOPASSWD:ALL' | sudo tee /etc/sudoers.d/vagrant-nopasswd
    sudo chmod 0440 /etc/sudoers.d/vagrant-nopty
    sudo chmod 0440 /etc/sudoers.d/vagrant-nopasswd

    if ! command -v ansible >/dev/null; then
      sudo apt-get update
      sudo apt-get install -y software-properties-common
      sudo apt-add-repository -y ppa:ansible/ansible
      sudo apt-get update
      sudo apt-get install -y ansible
    fi
  SHELL

  config.vm.define "db_server" do |db|
    db.vm.network "private_network", ip: "192.168.56.10"

    db.vm.provision "db_provision", type: "ansible_local" do |ansible|
      ansible.become = true
      ansible.become_user = "root"
      ansible.compatibility_mode = "2.0"
      ansible.playbook = "infrastructure/ansible/database.yml"
      ansible.limit = "all"
    end
  end

  config.vm.define "web_server" do |web|
    web.vm.network "private_network", ip: "192.168.56.11"
    web.vm.network "forwarded_port", guest: 80, host: 8080
    
    web.vm.provision "web_provision", type: "ansible_local" do |ansible|
      ansible.become = true
      ansible.become_user = "root"
      ansible.compatibility_mode = "2.0"
      ansible.playbook = "infrastructure/ansible/webserver.yml"
      ansible.limit = "all"
    end
  end
end
