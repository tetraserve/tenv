#!/bin/bash -x

# Example for stg1, creating 3 wallets, specify random gen password.
# that will be strored in app.yml. also generated address will be stored together. 
# (later, you can change warm wallet to another one in db)
# this app.yml info are finally automatically put into config/peatio/seed/wallets.yml
# maybe that is only for the first time

# 10.0.10.13 is cryptosv-stg1

#bundle exec rake wallet:create['deposit','http://10.0.10.13:8545','randomstr1']
#bundle exec rake wallet:create['hot','http://10.0.10.13:8545','randomstr2']
#bundle exec rake wallet:create['warm','http://10.0.10.13:8545','randomstr3']

start_opendax() {
  sudo -u deploy bash <<EOS
  cd /home/deploy
  source /home/deploy/.rvm/scripts/rvm
  rvm install --quiet-curl 2.6.5
  rvm use --default 2.6.5
  gem install bundler
  cd opendax
  bundle install --path vendor/bundle
  bundle exec rake render:config
  bundle exec rake service:logagent
EOS
}

start_opendax
