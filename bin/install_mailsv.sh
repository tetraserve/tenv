#!/bin/bash -x

source /home/$USER/opendax/bin/install_lib.sh

# Install Let's encrypt(ssl)
# apt stuff is for Ubuntu 18.04 so, check again for Ubuntu 20.04
# https://certbot.eff.org/lets-encrypt/ubuntufocal-other
# 
# You have to do manual install steps after terraform install.
# See terraform/README.md
# 
install_mailsv() {
  sudo -u deploy bash <<EOS
  sudo apt-get update
  sudo apt-get install -y -q software-properties-common
  sudo add-apt-repository -y universe
  sudo add-apt-repository -y ppa:certbot/certbot
  sudo apt-get update
  sudo apt-get install -y -q certbot
EOS
}

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
  ufw allow 25/tcp
  ufw allow 587/tcp
  ufw allow 143/tcp
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
install_mailsv
install_firewall
