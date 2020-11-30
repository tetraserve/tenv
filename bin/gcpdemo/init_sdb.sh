#!/bin/bash

# Initialize GCP Compute Engine's external sdb disk
#  immediately after terraform:apply finish,
#   execute this as soon as possible because of a disk space shortage.
#    you have to move all docker's data to sdb disk mounted.

#  For user "deploy" in GCP Compute engine.

if [ $USER != "deploy" ]; then
    echo "You are not user 'deploy'"
    exit
fi

read -p "DANGER!!!: YOU ARE GOING TO FORMAT SDB DISK. ARE YOU OK? (y/N): " yn
case "$yn" in [yY]*) ;; *) echo "Abort." ; exit ;; esac

read -p "REALLY? (y/N): " yn
case "$yn" in [yY]*) ;; *) echo "Abort." ; exit ;; esac

cd /home/deploy/opendax

# just because start.sh of terraform launched all & cryptonodes.
bundle exec rake service:all[stop]
bundle exec rake service:cryptonodes[stop]
bundle exec rake docker:down

cd /home/deploy

# See GCP doc
# https://cloud.google.com/compute/docs/disks/add-persistent-disk?hl=ja

sudo mkfs.ext4 -m 0 -E lazy_itable_init=0,lazy_journal_init=0,discard /dev/sdb
sudo mkdir -p /mnt/disks/sdb
sudo mount -o discard,defaults /dev/sdb /mnt/disks/sdb
sudo chmod a+w /mnt/disks/sdb

# Move docker's data to sdb 
sudo mv ~/docker_volumes /mnt/disks/sdb
sudo ln -s /mnt/disks/sdb/docker_volumes /home/deploy/docker_volumes

# For reboot
sudo cp /etc/fstab /etc/fstab.backup
echo UUID=`sudo blkid -s UUID -o value /dev/sdb` /mnt/disks/sdb ext4 discard,defaults,nofail 0 2 | sudo tee -a /etc/fstab
cat /etc/fstab

echo "Finished."