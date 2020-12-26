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

  desc 'Run backend (db)'
  task :backend, [:command] do |task, args|
    args.with_defaults(:command => 'start')

    def start
      puts '----- Starting backend -----'
      sh "mkdir -p #{@config['app']['docker_volumes_path']}/db_data"
      #sh "sudo chmod a+w #{@config['app']['docker_volumes_path']}/db_data"
      sh 'docker-compose up -d db'
    end

    def stop
      puts '----- Stopping backend -----'
      sh 'docker-compose rm -fs db'
    end


    @switch.call(args, method(:start), method(:stop))
  end

  desc 'Run app'
  task :app, [:command] do |task, args|
    args.with_defaults(:command => 'start')

    def start
      puts '----- Starting app -----'
      sh 'docker-compose up -d app'
    end

    def stop
      puts '----- Stopping app -----'
      sh 'docker-compose rm -fs app'
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
      Rake::Task["service:backend"].invoke('start')
      sleep(5)
      Rake::Task["service:proxy"].invoke('start')
      Rake::Task["service:pma"].invoke('start')
      Rake::Task["service:app"].invoke('start')
    end

    def stop
      Rake::Task["service:app"].invoke('stop')
      Rake::Task["service:pma"].invoke('stop')
      Rake::Task["service:proxy"].invoke('stop')
      Rake::Task["service:backend"].invoke('stop')
    end

    @switch.call(args, method(:start), method(:stop))
  end
end
