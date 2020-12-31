require 'yaml'
require 'base64'
require 'erb'
require "digest"
require 'json'

UTILS_PATH = 'master_config/utils.yml'.freeze
DEPLOY_PATH = 'master_config/deploy.yml'.freeze

######## START First time after git clone ########

#### Generate master.key
unless (File.exist?("config/master.key")) then
  puts "Welcome. It seems you are using this repository for the first time."
  puts " Making master.key for the system (only once)."
  print "  Please input master password :"
  input = STDIN.gets.chomp
  sha256 = Digest::SHA256.new
  sha256.update(input)
  File.write('config/master.key', sha256.hexdigest)
end
# Check master key
hash =Digest::SHA256.hexdigest(File.read('config/master.key'))
if (hash != '092f62296f5056e38ee95615df792506ab8a11a3db86a20cc841be0766b71255') then
  puts "Incorrect config/master.key. Erase it and retry by 'bundle exec rake -T'"
  exit
end

######## END First time after git clone ########

conf = JSON.parse(File.read('./config/render.json'))
CONFIG_PATH = "./master_config/#{conf['app']}.app.yml"
@config = YAML.load_file(CONFIG_PATH)

if (conf['app'] != "base") then
  # Special macro
  @config['database']['docker_volumes_path'].gsub!(/__HOME__/, ENV['HOME'])
  @config['database']['password'].gsub!(
    /__DB_PASSORD__/, File.read("./config/secrets/db_password.txt").strip)
  @config['pma']['basic_auth'].gsub!(
    /__PMA_AUTH__/, File.read("./config/secrets/pma_auth.txt").strip)
end
@utils = YAML.load_file(UTILS_PATH)
@deploy = YAML.load_file(DEPLOY_PATH)

# Add your own tasks in files placed in lib/tasks ending in .rake
Dir.glob('lib/tasks/*.rake').each do |task|
  load task
end