#!/bin/bash -x

start_tenv() {
  sudo -u deploy bash <<EOS
  cd /home/deploy
  source /home/deploy/.rvm/scripts/rvm
  rvm install --quiet-curl 2.7.2
  rvm use --default 2.7.2
  gem install bundler
  cd tenv
  bundle install --path vendor/bundle
  bundle exec rake render:config
EOS
}

start_tenv
