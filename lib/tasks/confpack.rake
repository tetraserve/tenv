require 'fog/google'
require_relative '../dockerconf/simple_cipher'

namespace :confpack do

  @deploy_secrets_basename  = "tenv_confpack_deploy_secrets"
  @secrets_basename        = "tenv_confpack_secrets"
  @password = File.read('config/master.key').strip
  @bucket = {}

  top_level = self

  using Module.new {
    refine(top_level.singleton_class) do
      def check_filename(fn)
        if (m = fn.match(/[-a-zA-Z0-9]+/)) then
          if (m[0] == fn) then
            if (fn.length >= 1)
              return true
            end
          end
        end
        puts ("Specify filename [-a-zA-Z0-9] and min length 1")
        false
      end
      def set_bucket
        Dir.chdir('config') do
          unless (File.exist?("confpack.json.enc")) then
            puts "Not found config/confpack.json.enc."
            puts "At first, you have to input 3 values to use (only once)."
            print "Bucket name: "
            @bucket['name'] = STDIN.gets.chomp
            print "Access key: "
            @bucket['accessKey'] = STDIN.gets.chomp
            print "Secret key: "
            @bucket['secretKey'] = STDIN.gets.chomp
            File.write('confpack.json.enc',
              Dockerconf::SimpleCipher::encrypt_string(@bucket.to_json)
            )
          end
          @bucket = JSON.parse(
            Dockerconf::SimpleCipher::decrypt_string(
              File.read('confpack.json.enc').strip
            )
          )
      end
      end
      def ls(filter)
        set_bucket
        begin
          google_storage = Fog::Storage::Google.new(
            :google_storage_access_key_id => @bucket['accessKey'],
            :google_storage_secret_access_key =>  @bucket['secretKey']
          )
          content = google_storage.get_bucket(@bucket['name'])
          count = 0
          content.body['Contents'].each { | file |
            if (file['Key'].start_with?(filter)) then
              count += 1
              if (m = file['Key'].match(/_([^._]+?)\.tgz/)) then
                puts "#{m[1]}"
              end
            end
          }
          if (count <= 0) then
            puts 'No file.'
          end
        rescue
          puts "Cannot access to GCP."
          puts "Maybe because of incorrect config/confpack.json.enc. Erase it and retry."
          return
        end
      end
      def save(tgz_basename, filename, args)
        set_bucket
        Dir.chdir('..') do
          sh "tar cvzf #{tgz_basename}_#{filename}.tgz #{args}"
          # mac: brew install openssl
          sh "openssl aes-256-cbc -e -pbkdf2 "+
              "-in #{tgz_basename}_#{filename}.tgz "+
              "-out #{tgz_basename}_#{filename}.tgz.enc "+
              "-pass pass:#{@password}"
          sh "rm -f #{tgz_basename}_#{filename}.tgz"
        end
        begin
          google_storage = Fog::Storage::Google.new(
            :google_storage_access_key_id => @bucket['accessKey'],
            :google_storage_secret_access_key =>  @bucket['secretKey']
          )
          content = File.read("../#{tgz_basename}_#{filename}.tgz.enc")
          google_storage.put_object(
            @bucket['name'], "#{tgz_basename}_#{filename}.tgz.enc", content)
        rescue
          puts "Cannot access to GCP."
          puts "Maybe because of incorrect config/confpack.json.enc. Erase it and retry."
        ensure
          sh "rm -f ../#{tgz_basename}_#{filename}.tgz.enc"
        end
      end
      def load(tgz_basename, filename)
        set_bucket
        begin
          google_storage = Fog::Storage::Google.new(
            :google_storage_access_key_id => @bucket['accessKey'],
            :google_storage_secret_access_key =>  @bucket['secretKey']
          )
          content = google_storage.get_object(
            @bucket['name'], "#{tgz_basename}_#{filename}.tgz.enc")
          File.write("../#{tgz_basename}_#{filename}.tgz.enc", content.body)
        rescue
          puts "File not found."
          puts "Or cannot access to GCP."
          puts "Check config/confpack.json.enc. If wrong, erase it and retry."
          return
        end
        Dir.chdir('..') do
          # mac: brew install openssl
          sh "openssl aes-256-cbc -d -pbkdf2 "+
              "-in #{tgz_basename}_#{filename}.tgz.enc "+
              "-out #{tgz_basename}_#{filename}.tgz "+
              "-pass pass:#{@password}"
          sh "rm -f #{tgz_basename}_#{filename}.tgz.enc"
          sh "tar xvzf #{tgz_basename}_#{filename}.tgz"
          sh "rm -f #{tgz_basename}_#{filename}.tgz"
        end
      end
    end
  }

  desc 'List GCP storage bucket files.'
  task :ls do
    ls(@secrets_basename)
  end

  desc 'List GCP storage bucket files.'
  task :ls_deploy_secrets do
    ls(@deploy_secrets_basename)
  end

  desc 'Save deploy_secrets/* into GCP storage bucket [filename].'
  task :save_deploy_secrets, [:file] do |_, args|
    if (args.file.nil?) then
      puts "Specify [filename]"
    else
      if (!check_filename(args.file)) then
        next
      end
      tgzargs = "--exclude .gitkeep tenv/deploy_secrets"
      save("#{@deploy_secrets_basename}", args.file, tgzargs)
    end
  end

  desc 'Load deploy_secrets/* from GCP storage bucket [filename].'
  task :load_deploy_secrets, [:file] do |_, args|
    if (args.file.nil?) then
      puts "Specify [filename]"
    else
      if (!check_filename(args.file)) then
        next
      end
      load("#{@deploy_secrets_basename}", args.file)
    end
  end

  desc 'Save all secrets into GCP storage bucket [filename].'
  task :save, [:file] do |_, args|
    if (args.file.nil?) then
      puts "Specify [filename]"
    else
      if (!check_filename(args.file)) then
        next
      end
      tgzargs = "--exclude .gitkeep tenv/config/secrets"
      save("#{@secrets_basename}", args.file, tgzargs)
    end
  end

  desc 'Load all secrets from GCP storage bucket [filename].'
  task :load, [:file] do |_, args|
    if (args.file.nil?) then
      puts "Specify [filename]"
    else
      if (!check_filename(args.file)) then
        next
      end
      load("#{@secrets_basename}", args.file)
    end
  end

end