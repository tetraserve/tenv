namespace :db do

  def mysql_cli
    return "mysql -u root -h db -P 3306 -pchangeme"
  end

  desc 'Create database'
  task :create do
    sh 'docker-compose run --rm snn bundle exec rake db:create'
  end

  desc 'Migrate database'
  task :migrate do
    sh 'docker-compose run --rm snn bundle exec rake db:migrate'
  end

  desc 'Load database dump'
  task :load => :create do
    sh %Q{cat data/mysql/snn_production.sql | docker-compose run --rm db #{mysql_cli} snn_production}
    sh 'docker-compose run --rm snn bundle exec rake db:migrate'
  end

  desc 'Drop all databases'
  task :drop do
    puts "Disabled (see source)"
    #sh %q(docker-compose run --rm db /bin/sh -c "mysql -u root -h db -P 3306 -pchangeme -e 'DROP DATABASE snn_production'")
  end

  desc 'Database Console'
  task :console do
    sh "docker-compose run --rm db #{mysql_cli}"
  end

  desc 'Backup to [local(~/snnenv_datetime.sql.tar.bz2)|remote]'
  task :backup do
  end

  desc 'Restore from file in ~ [snnenv_datetime.sql.tar.bz2]'
  task :restore do
  end

end
