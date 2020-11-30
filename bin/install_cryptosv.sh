#!/bin/bash -x

source /home/$USER/opendax/bin/install_lib.sh

# 30303(tcp/udp) parity port
# 8333 bitcoind port mainnet
# 18333 bitcoind port testnet
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
  ufw allow 30303/tcp
  ufw allow 30303/udp
  ufw allow 8333/tcp
  ufw allow 18333/tcp
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
