[webserver]
${web_ip} ansible_user=root ansible_host=${web_ip} ansible_ssh_private_key_file=~/.ssh/id_rsa

[database]
${db_ip} ansible_user=root ansible_host=${db_ip} ansible_ssh_private_key_file=~/.ssh/id_rsa
