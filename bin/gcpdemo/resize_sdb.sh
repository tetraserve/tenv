#!/bin/bash

# Resize GCP Compute Engine(VM)'s external sdb disk
#  after terraform:apply(resize) finish, execute this
#  (have to be done to fix filesystem meta info)

#  For user "deploy" in GCP Compute engine.

if [ $USER != "deploy" ]; then
    echo "You are not user 'deploy'"
    exit
fi

read -p "You are going to fix sdb disk size info. Are you OK? (y/N): " yn
case "$yn" in [yY]*) ;; *) echo "Abort." ; exit ;; esac

cd /home/deploy/opendax

# just because start.sh of terraform launched all & cryptonodes.
bundle exec rake service:all[stop]
bundle exec rake service:cryptonodes[stop]
bundle exec rake docker:down

cd /home/deploy

# See GCP doc
# https://cloud.google.com/compute/docs/disks/add-persistent-disk?hl=ja

df -h /dev/sdb
sudo resize2fs /dev/sdb
df -h /dev/sdb

echo "Finished."