require_relative '../opendax/util'

namespace :service do
  ENV['APP_DOMAIN'] = @config['app']['domain']

  @switch = Proc.new do |args, start, stop|
    case args.command
    when 'start'
      if (!Opendax::Util::check_hostname_and_status) then
        Opendax::Util::show_command_status
        next
      end  
      start.call
    when 'stop'
      stop.call
    when 'restart'
      stop.call
      start.call
    else
      puts "unknown command #{args.command}"
    end
  end

  desc 'Run Traefik (reverse-proxy)'
  task :proxy, [:command] do |task, args|
    args.with_defaults(:command => 'start')

    def start
      puts '----- Starting the proxy -----'
      File.new('config/acme.json', File::CREAT, 0600) unless File.exist? 'config/acme.json'
      sh 'docker-compose up -d proxy'
    end

    def stop
      puts '----- Stopping the proxy -----'
      sh 'docker-compose rm -fs proxy'
    end

    @switch.call(args, method(:start), method(:stop))
  end

  desc 'Run backend (vault db redis rabbitmq)'
  task :backend, [:command] do |task, args|
    args.with_defaults(:command => 'start')

    def start
      puts '----- Starting dependencies -----'
      puts "----- Vault mode: #{@config['vault']['mode']} -----"
      sh "mkdir -p #{@config['app']['docker_volumes_path']}/vault_data"
      sh "sudo chmod a+w #{@config['app']['docker_volumes_path']}/vault_data"
      sh "mkdir -p #{@config['app']['docker_volumes_path']}/db_data"
      sh "sudo chmod a+w #{@config['app']['docker_volumes_path']}/db_data"
      sh "mkdir -p #{@config['app']['docker_volumes_path']}/redis_data"
      sh "sudo chmod a+w #{@config['app']['docker_volumes_path']}/redis_data"
      sh "mkdir -p #{@config['app']['docker_volumes_path']}/rabbitmq_data"
      sh "sudo chmod a+w #{@config['app']['docker_volumes_path']}/rabbitmq_data"
      sh 'docker-compose up -d vault db redis rabbitmq'
      sh 'docker-compose run --rm vault secrets enable totp \
              && docker-compose run --rm vault secrets disable secret \
              && docker-compose run --rm vault secrets enable transit \
              && docker-compose run --rm vault secrets enable -path=secret -version=1 kv \
              || echo Vault already enabled' if @config['vault']['mode'] == 'development'
      sleep 7 # time for db to start, we can get connection refused without sleeping
    end

    def stop
      puts '----- Stopping dependencies -----'
      sh 'docker-compose rm -fs vault db redis rabbitmq'
    end


    @switch.call(args, method(:start), method(:stop))
  end

  desc 'Run influxdb'
  task :influxdb, [:command] do |task, args|
    args.with_defaults(:command => 'start')

    def start
      puts '----- Starting influxdb -----'
      sh "mkdir -p #{@config['app']['docker_volumes_path']}/influx_data"
      sh "sudo chmod a+w #{@config['app']['docker_volumes_path']}/influx_data"
      sh 'docker-compose up -d influxdb'
      sh 'docker-compose exec influxdb bash -c "cat influxdb.sql | influx"'
    end

    def stop
      puts '----- Stopping influxdb -----'
      sh 'docker-compose rm -fs influxdb'
    end

    @switch.call(args, method(:start), method(:stop))
  end

  desc '[Optional] Run arke-maker'
  task :arke_maker, [:command] do |task, args|
    args.with_defaults(:command => 'start')

    def start
      puts '----- Starting arke -----'
      sh 'docker-compose up -d arke-maker'
    end

    def stop
      puts '----- Stopping arke -----'
      sh 'docker-compose rm -fs arke-maker'
    end

    @switch.call(args, method(:start), method(:stop))
  end

  desc '[Optional] Run arke proxy'
  task :arke_proxy, [:command] do |task, args|
    @containers = %w[arke arke-etl]
    args.with_defaults(:command => 'start')

    def start
      puts '----- Starting arke-proxy -----'
      sh "docker-compose up -d #{@containers.join(' ')}"
    end

    def stop
      puts '----- Stopping arke-proxy -----'
      sh "docker-compose rm -fs #{@containers.join(' ')}"
    end

    @switch.call(args, method(:start), method(:stop))
  end

  desc '[Optional] Run peatio daemons (ranger, peatio daemons)'
  task :daemons, [:command] do |task, args|
    @daemons = %w[ranger withdraw_audit blockchain global_state deposit_collection deposit_collection_fees deposit_coin_address slave_book pusher_market pusher_member matching order_processor trade_executor withdraw_coin k market_ticker]

    args.with_defaults(:command => 'start')

    def start
      puts '----- Starting peatio daemons -----'
      sh "docker-compose up -d #{@daemons.join(' ')}"
    end

    def stop
      puts '----- Stopping peatio daemons -----'
      sh "docker-compose rm -fs #{@daemons.join(' ')}"
    end

    @switch.call(args, method(:start), method(:stop))
  end

  desc '[Optional] Run cryptonodes'
  task :cryptonodes, [:command] do |task, args|
    args.with_defaults(:command => 'start')

    def start
      puts '----- Starting cryptonodes -----'
      sh "mkdir -p #{@config['app']['docker_volumes_path']}/parity_data"
      sh "sudo chmod a+w #{@config['app']['docker_volumes_path']}/parity_data"
      sh "sudo chown 1000:1000 #{@config['app']['docker_volumes_path']}/parity_data"
      sh "mkdir -p #{@config['app']['docker_volumes_path']}/bitcoind_data"
      sh "sudo chmod a+w #{@config['app']['docker_volumes_path']}/bitcoind_data"
      sh 'docker-compose up -d parity bitcoind'
    end

    def stop
      puts '----- Stopping cryptonodes -----'
      sh 'docker-compose rm -fs parity bitcoind'
    end

    @switch.call(args, method(:start), method(:stop))
  end

  desc 'Run setup hooks for peatio, barong'
  task :setup, [:command] do |task, args|
    if args.command != 'stop'
      puts '----- Running hooks -----'
      sh 'docker-compose run --rm peatio bash -c "./bin/link_config && bundle exec rake db:create db:migrate"'
      sh 'docker-compose run --rm peatio bash -c "./bin/link_config && bundle exec rake db:seed"'
      sh 'docker-compose run --rm barong bash -c "./bin/init_config && bundle exec rake db:create db:migrate"'
      sh 'docker-compose run --rm barong bash -c "./bin/link_config && bundle exec rake db:seed"'
    end
  end

  desc 'Run mikro app (barong, peatio)'
  task :app, [:command] => [:proxy, :backend, :setup] do |task, args|
    args.with_defaults(:command => 'start')

    def start
      puts '----- Starting app -----'
      sh 'docker-compose up -d peatio barong gateway'
    end

    def stop
      puts '----- Stopping app -----'
      sh 'docker-compose rm -fs peatio barong gateway'
    end

    @switch.call(args, method(:start), method(:stop))
  end

  desc 'Run the frontend application'
  task :frontend, [:command] do |task, args|
    args.with_defaults(:command => 'start')

    def start
      puts '----- Starting the frontend -----'
      sh 'docker-compose up -d frontend'
    end

    def stop
      puts '----- Stopping the frontend -----'
      sh 'docker-compose rm -fs frontend'
    end

    @switch.call(args, method(:start), method(:stop))
  end

  desc 'Run the tower application'
  task :tower, [:command] do |task, args|
    args.with_defaults(:command => 'start')

    def start
      puts '----- Starting the tower -----'
      sh 'docker-compose up -d tower'
    end

    def stop
      puts '----- Stopping the tower -----'
      sh 'docker-compose rm -fs tower'
    end

    @switch.call(args, method(:start), method(:stop))
  end

  desc '[Optional] Run utils (postmaster)'
  task :utils, [:command] do |task, args|
    args.with_defaults(:command => 'start')

    def start
      puts '----- Starting utils -----'
      sh 'docker-compose up -d postmaster'
    end

    def stop
      puts '----- Stopping Utils -----'
      sh 'docker-compose rm -fs postmaster'
    end

    @switch.call(args, method(:start), method(:stop))
  end

  desc '[Optional] Run monitoring'
  task :monitoring, [:command] do |task, args|
    args.with_defaults(:command => 'start')

    def start
      puts '----- Starting monitoring -----'
      sh 'docker-compose up -d node_exporter'
      sh 'docker-compose up -d cadvisor'
    end

    def stop
      puts '----- Stopping monitoring -----'
      sh 'docker-compose rm -fs node_exporter'
      sh 'docker-compose rm -fs cadvisor'
    end

    @switch.call(args, method(:start), method(:stop))
  end

  desc '[Optional] Run superset'
  task :superset, [:command] do |task, args|
    args.with_defaults(:command => 'start')

    def start
      sh "mkdir -p #{@config['app']['docker_volumes_path']}/superset_db"
      sh "sudo chmod a+w #{@config['app']['docker_volumes_path']}/superset_db"
      conf = @utils['superset']
      init_params = [
        '--app', 'superset',
        '--firstname', 'Admin',
        '--lastname', 'Superset',
        '--username', conf['username'],
        '--email', conf['email'],
        '--password', conf['password']
      ].join(' ')

      puts '----- Initializing Superset -----'
      sh [
        'docker-compose run --rm superset',
        'sh -c "',
        "fabmanager create-admin #{init_params}",
        '&& superset db upgrade',
        '&& superset init"'
      ].join(' ')

      puts '----- Starting Superset -----'
      sh 'docker-compose up -d superset'
    end

    def stop
      puts '----- Stopping Superset -----'
      sh 'docker-compose rm -fs superset'
    end

    @switch.call(args, method(:start), method(:stop))
  end

  desc '[Optional] Run phpmyadmin'
  task :pma, [:command] do |task, args|
    args.with_defaults(:command => 'start')

    def start
      puts '----- Starting the phpmyadmin -----'
      sh 'docker-compose up -d pma'
    end

    def stop
      puts '----- Stopping the phpmyadmin -----'
      sh 'docker-compose rm -fs pma'
    end

    @switch.call(args, method(:start), method(:stop))
  end

  desc '[Optional] Run Logging'
  task :logging, [:command] do |task, args|
    args.with_defaults(:command => 'start')

    def start
      puts '----- Starting the Logging -----'
      sh "mkdir -p #{@config['app']['docker_volumes_path']}/es_data"
      sh "sudo chmod a+w #{@config['app']['docker_volumes_path']}/es_data"
      sh 'docker-compose up -d logspout logstash kibana elasticsearch'
    end

    def stop
      puts '----- Stopping the Logging -----'
      sh 'docker-compose rm -fs logspout logstash kibana elasticsearch'
    end

    @switch.call(args, method(:start), method(:stop))
  end

  desc '[Optional] Run Mailserver'
  task :mailsv, [:command] do |task, args|
    args.with_defaults(:command => 'start')

    def start
      puts '----- Starting the Mailserver -----'
      sh "mkdir -p #{@config['app']['docker_volumes_path']}/maildata"
      sh "sudo chmod a+w #{@config['app']['docker_volumes_path']}/maildata"
      sh "mkdir -p #{@config['app']['docker_volumes_path']}/mailstate"
      sh "sudo chmod a+w #{@config['app']['docker_volumes_path']}/mailstate"
      sh "mkdir -p #{@config['app']['docker_volumes_path']}/maillogs"
      sh "sudo chmod a+w #{@config['app']['docker_volumes_path']}/maillogs"
      sh 'docker-compose up -d mailsv'
    end

    def stop
      puts '----- Stopping the Mailserver -----'
      sh 'docker-compose rm -fs mailsv'
    end

    @switch.call(args, method(:start), method(:stop))
  end

  desc '[Optional] Run Nginx'
  task :nginx, [:command] do |task, args|
    args.with_defaults(:command => 'start')

    def start
      puts '----- Starting the Nginx -----'
      sh "mkdir -p #{@config['app']['docker_volumes_path']}/nginx_data"
      sh "sudo chmod a+w #{@config['app']['docker_volumes_path']}/nginx_data"
      sh 'docker-compose up -d nginx'
    end

    def stop
      puts '----- Stopping the Nginx -----'
      sh 'docker-compose rm -fs nginx'
    end

    @switch.call(args, method(:start), method(:stop))
  end

  desc '[Optional] Run LogAgent'
  task :logagent, [:command] do |task, args|
    args.with_defaults(:command => 'start')

    def start
      puts '----- Starting the LogAgent -----'
      sh 'docker-compose up -d logspout_agent'
    end

    def stop
      puts '----- Stopping the LogAgent -----'
      sh 'docker-compose rm -fs logspout_agent'
    end

    @switch.call(args, method(:start), method(:stop))
  end

  desc '[Optional] Run LogServer'
  task :logsv, [:command] do |task, args|
    args.with_defaults(:command => 'start')

    def start
      puts '----- Starting the LogServer -----'
      sh "mkdir -p #{@config['app']['docker_volumes_path']}/es_sv_data"
      sh "sudo chmod a+w #{@config['app']['docker_volumes_path']}/es_sv_data"
      File.new('config/acme_logsv.json', File::CREAT, 0600) unless File.exist? 'config/acme_logsv.json'
      sh 'docker-compose up -d proxylogsv logstashsv elasticsearchsv kibanasv'
    end

    def stop
      puts '----- Stopping the LogServer -----'
      sh 'docker-compose rm -fs proxylogsv logstashsv elasticsearchsv kibanasv'
    end

    @switch.call(args, method(:start), method(:stop))
  end

  desc 'Run the micro app with dependencies (does not run Optional)'
  task :all, [:command] => 'render:config' do |task, args|
    args.with_defaults(:command => 'start')

    def start
      Rake::Task["service:proxy"].invoke('start')
      Rake::Task["service:backend"].invoke('start')
      puts 'Wait 5 second for backend'
      sleep(5)
      Rake::Task["service:setup"].invoke('start')
      Rake::Task["service:app"].invoke('start')
      Rake::Task["service:frontend"].invoke('start')
      Rake::Task["service:tower"].invoke('start')
      Rake::Task["service:influxdb"].invoke('start') if @config['arke_proxy']['enabled']
      Rake::Task["service:arke_proxy"].invoke('start') if @config['arke_proxy']['enabled']
      Rake::Task["service:utils"].invoke('start')
      Rake::Task["service:daemons"].invoke('start')
    end

    def stop
      Rake::Task["service:proxy"].invoke('stop')
      Rake::Task["service:backend"].invoke('stop')
      Rake::Task["service:setup"].invoke('stop')
      Rake::Task["service:app"].invoke('stop')
      Rake::Task["service:frontend"].invoke('stop')
      Rake::Task["service:tower"].invoke('stop')
      Rake::Task["service:influxdb"].invoke('stop')
      Rake::Task["service:arke_proxy"].invoke('stop')
      Rake::Task["service:utils"].invoke('stop')
      Rake::Task["service:daemons"].invoke('stop')
    end

    @switch.call(args, method(:start), method(:stop))
  end
end
