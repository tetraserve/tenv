namespace :docker do
    desc 'Stop all runnning docker contrainers'
    task :down do
        sh 'docker-compose down'
    end

    desc 'Clean up all docker volumes'
    task :clean do
        puts "Unavailable (See source code)"
        #sh 'docker volume prune -f'
    end
end
