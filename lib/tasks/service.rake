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

  desc 'Run backend (db redis)'
  task :backend, [:command] do |task, args|
    args.with_defaults(:command => 'start')

    def start
      puts '----- Starting dependencies -----'
      sh "mkdir -p #{@config['app']['docker_volumes_path']}/db_data"
      sh "sudo chmod a+w #{@config['app']['docker_volumes_path']}/db_data"
      sh "mkdir -p #{@config['app']['docker_volumes_path']}/redis_data"
      sh "sudo chmod a+w #{@config['app']['docker_volumes_path']}/redis_data"
      sh 'docker-compose up -d db redis'
      sleep 7 # time for db to start, we can get connection refused without sleeping
    end

    def stop
      puts '----- Stopping dependencies -----'
      sh 'docker-compose rm -fs db redis'
    end


    @switch.call(args, method(:start), method(:stop))
  end

  desc 'Run app (barong, peatio)'
  task :app, [:command] => [:proxy, :backend] do |task, args|
    args.with_defaults(:command => 'start')

    def start
      puts '----- Starting app -----'
      sh 'docker-compose up -d peatio'
    end

    def stop
      puts '----- Stopping app -----'
      sh 'docker-compose rm -fs peatio'
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

  desc 'Run the micro app with dependencies (does not run Optional)'
  task :all, [:command] => 'render:config' do |task, args|
    args.with_defaults(:command => 'start')

    def start
      Rake::Task["service:proxy"].invoke('start')
      Rake::Task["service:backend"].invoke('start')
      puts 'Wait 5 second for backend'
      sleep(5)
      Rake::Task["service:app"].invoke('start')
    end

    def stop
      Rake::Task["service:proxy"].invoke('stop')
      Rake::Task["service:backend"].invoke('stop')
      Rake::Task["service:app"].invoke('stop')
    end

    @switch.call(args, method(:start), method(:stop))
  end
end
