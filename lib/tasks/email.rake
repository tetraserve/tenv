namespace :email do

  top_level = self


  desc 'Init mailboxes & aliases on seed yml(WARN: CLEAR&recreate)'
  task :init do
    config_path =File.expand_path('./config/mailsv')
    ENV['CONFIG_PATH']=config_path
    ENV['IMAGE_NAME']=@config['images']['mailsv']
    sh "rm -f ./config/mailsv/postfix-accounts.cf"
    sh "rm -f ./config/mailsv/postfix-virtual.cf"
    Dir.chdir("./bin") {
      @config['mailsv']['emails'].each { |r|
        sh "/bin/bash -c 'source ./setup_mailsv.sh email add #{r['address']} #{r['password']}'"
      }
      @config['mailsv']['aliases'].each { |r|
        sh  "/bin/bash -c 'source ./setup_mailsv.sh alias add #{r['address']} #{r['to']}'"
      }
      sh "/bin/bash -c 'source ./setup_mailsv.sh email list'"
      sh "/bin/bash -c 'source ./setup_mailsv.sh alias list'"
    }
  end

end
