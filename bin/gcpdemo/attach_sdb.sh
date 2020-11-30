#!/bin/bash

# Attach GCP Compute Engine(VM)'s external sdb disk
#  immediately after terraform:apply finish,
#   execute this as soon as possible because of a disk space shortage.
#  (Use this when VM is destroyed and re-created by terraform
#   because of boot disk size change or something)

#  For user "deploy" in GCP Compute engine.

if [ $USER != "deploy" ]; then
    echo "You are not user 'deploy'"
    exit
fi

read -p "You are going to attach sdb disk. Are you OK? (y/N): " yn
case "$yn" in [yY]*) ;; *) echo "Abort." ; exit ;; esac

cd /home/deploy/opendax

# just because start.sh of terraform launched all & cryptonodes.
bundle exec rake service:all[stop]
bundle exec rake service:cryptonodes[stop]
bundle exec rake docker:down

cd /home/deploy

# See GCP doc
# https://cloud.google.com/compute/docs/disks/add-persistent-disk?hl=ja

sudo mkdir -p /mnt/disks/sdb
sudo mount -o discard,defaults /dev/sdb /mnt/disks/sdb
sudo chmod a+w /mnt/disks/sdb

# Attach docker's data to sdb 
sudo rm -rf ~/docker_volumes
sudo ln -s /mnt/disks/sdb/docker_volumes /home/deploy/docker_volumes

# For reboot
sudo cp /etc/fstab /etc/fstab.backup
echo UUID=`sudo blkid -s UUID -o value /dev/sdb` /mnt/disks/sdb ext4 discard,defaults,nofail 0 2 | sudo tee -a /etc/fstab
cat /etc/fstab

echo "Finished."