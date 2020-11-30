#!/bin/bash
#Install Terraform plugin for sakura cloud
#https://docs.usacloud.jp/terraform-v1/installation/

cd ~
mkdir -p .terraform.d/plugins
cd .terraform.d/plugins
wget https://github.com/sacloud/terraform-provider-sakuracloud/releases/download/v2.3.1/terraform-provider-sakuracloud_2.3.1_linux-amd64.zip
unzip terraform-provider-sakuracloud_2.3.1_linux-amd64.zip
