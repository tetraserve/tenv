
# For Ubuntu 20.04 LTS minimal

COMPOSE_VERSION="1.27.4"
COMPOSE_URL="https://github.com/docker/compose/releases/download/$COMPOSE_VERSION/docker-compose-$(uname -s)-$(uname -m)"

# Needed for elasticsearch
fix_system() {
  sudo bash <<EOS
  echo "vm.max_map_count = 262144" >> /etc/sysctl.conf
  sysctl -p
EOS
}

# bootstrap script
# Note) DEBIAN_FRONTEND for tzdata install screen stop
# https://serverfault.com/questions/949991/how-to-install-tzdata-on-a-ubuntu-docker-image
# At first, sleep for seconds to initial image to be updated by GCP infra or other.
install_core() {
  sudo bash <<EOS
sleep 10
apt-get update
export DEBIAN_FRONTEND=noninteractive
apt-get install -y tzdata
ln -fs /usr/share/zoneinfo/Asia/Tokyo /etc/localtime
dpkg-reconfigure --frontend noninteractive tzdata
apt-get install -y -q git tmux gnupg2 dirmngr dbus htop curl libmariadbclient-dev-compat build-essential
apt-get install -y -q vim
update-alternatives --set editor /usr/bin/vim.tiny
apt-get install -y -q monit
apt-get install -y -q munin-node
apt-get install -y -q mysql-client
EOS
}

log_rotation() {
  sudo bash <<EOS
mkdir -p /etc/docker
echo '
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "10"
  }
}' > /etc/docker/daemon.json
EOS
}

# Docker installation
install_docker() {
  export VERSION=20.10.1
  curl -fsSL https://get.docker.com/ | bash
  sudo bash <<EOS
usermod -a -G docker $USER
curl -L "$COMPOSE_URL" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
EOS
}

# Do no special things on GCP compute engine
#activate_gcloud() {
#  sudo -u deploy bash <<EOS
#  gcloud auth configure-docker --quiet
#EOS
#}

install_ruby() {
  sudo -u deploy bash <<EOS
  gpg2 --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB
  curl -sSL https://get.rvm.io | bash -s stable
  echo 'alias be="bundle exec"' >> ~/.bashrc
  echo 'alias rails="bundle exec rails"' >> ~/.bashrc
  echo 'alias rake="bundle exec rake"' >> ~/.bashrc
EOS
}

prepare_docker_volumes() {
  sudo -u deploy bash <<EOS
  mkdir -p /home/deploy/docker_volumes
  chmod a+w /home/deploy/docker_volumes
EOS
}