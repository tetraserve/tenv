require_relative '../opendax/util'
require 'pathname'

namespace :tf do

  top_level = self

  using Module.new {
    TERRAFORM_PATH = Pathname.new('./terraform')
    refine(top_level.singleton_class) do
      def set_env
        #ENV['GOOGLE_CREDENTIALS'] = @deploy['gcp']['credentials']
        conf = JSON.parse(File.read('./config/render.json'))
        if (conf['app']=='sample'||conf['app']=='local') then
          puts 'Set r:c[prd|base|stg1-3] for terraform.'
          return false
        end
        if (ENV['USER']=='deploy') then
          puts 'User deploy cannot deploy.'
          return false
        end
        true
      end
      def delete_tf_files
        return if (!@deploy['delete_tf_files'])
        Dir.glob("#{TERRAFORM_PATH}/**/*.tf", File::FNM_DOTMATCH).each do |file|
          sh "rm -f #{file}"
        end
      end
    end
  } 

  desc 'Set (c)loud platform for Terraform [gcp|hc]'
  task :c, [:kind] do |_, args|
    next if (!set_env)
    conf = JSON.parse(File.read('./config/render.json'))
    if (args.kind.nil? || (args.kind != 'gcp' && args.kind != 'hc')) then
      puts "Specify paramter [gcp|hc]."
      Opendax::Util::show_command_status
      next
    end
    conf['cloud'] = args.kind
    File.write('./config/render.json', conf.to_json)
    puts "Set cloud: #{conf['cloud']}"
    Opendax::Util::show_command_status
  end

  desc 'Initialize the Terraform configuration'
  # At very fist, after install terraform itself,
  # Maybe you have to execute terraform init manually in
  # subdir
  # for plugin install or something.
  task :init do
    next if (!set_env)
    delete_tf_files
    Rake::Task["render:config"].invoke
    conf = JSON.parse(File.read('./config/render.json'))
    Dir.chdir("terraform/#{conf['cloud']}/#{conf['app']}") {
      puts "Entering: terraform/#{conf['cloud']}/#{conf['app']}"
      bucket = @deploy['gcs']['terraform_bucket']
      prefix = "#{conf['cloud']}/#{conf['app']}"
      cmd = "terraform init -backend-config='bucket=#{bucket}' -backend-config='prefix=#{prefix}'"
      sh cmd do |ok, status|
      end
    }
  end

  desc 'Apply the Terraform configuration'
  task :apply do
    next if (!set_env)
    delete_tf_files
    Rake::Task["render:config"].invoke
    conf = JSON.parse(File.read('./config/render.json'))
    Dir.chdir("terraform/#{conf['cloud']}/#{conf['app']}") {
      puts "Entering: terraform/#{conf['cloud']}/#{conf['app']}"
      sh "terraform apply" do |ok, status|
      end
    }
  end

  desc 'Plan the Terraform configuration'
  task :plan do
    next if (!set_env)
    delete_tf_files
    Rake::Task["render:config"].invoke
    conf = JSON.parse(File.read('./config/render.json'))
    Dir.chdir("terraform/#{conf['cloud']}/#{conf['app']}") {
      puts "Entering: terraform/#{conf['cloud']}/#{conf['app']}"
      sh "terraform plan" do |ok, status|
      end
    }
  end

  desc 'Destroy the Terraform infrastructure'
  task :destroy do
    next if (!set_env)
    delete_tf_files
    Rake::Task["render:config"].invoke
    conf = JSON.parse(File.read('./config/render.json'))
    Dir.chdir("terraform/#{conf['cloud']}/#{conf['app']}") {
      puts "Entering: terraform/#{conf['cloud']}/#{conf['app']}"
      sh "terraform destroy" do |ok, status|
      end
    }
  end

  desc 'Show the Terraform infrastructure'
  task :show do
    next if (!set_env)
    delete_tf_files
    Rake::Task["render:config"].invoke
    conf = JSON.parse(File.read('./config/render.json'))
    Dir.chdir("terraform/#{conf['cloud']}/#{conf['app']}") {
      puts "Entering: terraform/#{conf['cloud']}/#{conf['app']}"
      sh "terraform show" do |ok, status|
      end
    }
  end
end
