#!/bin/bash -x

source /home/$USER/snnenv/bin/install_lib.sh

install_firewall() {
  sudo bash <<EOS
  apt install -y -q ufw
  systemctl enable ufw
  systemctl restart ufw
  ufw allow from 10.0.0.0/8
  ufw allow from 172.16.0.0/12
  ufw allow from 192.168.0.0/16
  ufw allow ssh
  ufw allow 822/tcp
  ufw allow 80/tcp
  ufw allow 8080/tcp
  ufw allow 1337/tcp
  ufw allow 443/tcp
  yes | ufw enable
  ufw reload
  ufw status verbose
EOS
}

# install_lib.sh
fix_system
install_core
log_rotation
install_docker
install_ruby
prepare_docker_volumes

#
install_firewall
