namespace :db do

  #docker exec -it container_name-mysql bash -c 'MYSQL_PWD=password mysqldump -u user db_name' 1> sql.dump
  
  def mysql_cli
    return "mysql -u root -h 127.0.0.1 -P 3306 -pchangeme"
  end

  def mysql_dump
    puts "Notice) As mysql 5.7 mysqldump."
    return "mysqldump -u root -h 127.0.0.1 -P 3306 -pchangeme"
  end

  # mysql8.0 client cannot handle 5.7 database as default
  def mysql_dump8
    puts "Notice) As mysql 8.0 mysqldump, using --skip-column-statistics.."
    return "mysqldump -u root -h 127.0.0.1 -P 3306 -pchangeme --skip-column-statistics"
  end

  desc 'Create database'
  task :create do
    sh 'docker-compose run --rm app bundle exec rake db:create'
  end

  desc 'Migrate database'
  task :migrate do
    sh 'docker-compose run --rm app bundle exec rake db:migrate'
  end

  desc 'Drop database'
  task :drop do
    sh 'docker-compose run --rm app bundle exec rake db:drop'
  end

  desc 'Database Console'
  task :console do
    sh "#{mysql_cli}"
  end

  desc 'Dump all databases'
  task :dump, [:file] do |_, args|
    if (args.file.nil?) then
      puts "Specify a output file(path)."
    else
      sh "#{mysql_dump8} --single-transaction --all-databases > #{args.file}"
    end
  end

  desc 'Dump all databases(using mysql5.7 client)'
  task :dump57, [:file] do |_, args|
    if (args.file.nil?) then
      puts "Specify a output file(path)."
    else
      sh "#{mysql_dump} --single-transaction --all-databases > #{args.file}"
    end
  end

  desc 'Restore database dump'
  task :restore, [:file] do |_, args|
    if (args.file.nil?) then
      puts "Specify a output file(path)."
    else
      sh "#{mysql_cli} < #{args.file}"
    end
  end

end