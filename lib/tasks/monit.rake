
require 'tempfile'

#How to setup monit and slack:
#https://www.dajocarter.com/posts/send-monit-alerts-to-slack/

namespace :monit do

  desc 'Setup monit'
  task :setup  do

    # Configs
    slack_webhook_url = @config['slack']['webhook_url']
    disk_threshold = @config['monit']['disk_threshold']

    # Find disks to be monitored (exclude boot disk and detached disk)
    df_lines = `df -h | grep -e '/dev/root' -e '/dev/sd[a-z]' | grep -v '/boot' | grep -v ' 0 100% '`
    puts "=== Disks found for monitoring:"
    puts df_lines
    puts "=== Disks in all:"
    puts `df -h`
    disks = []
    df_lines.each_line{ |line|
      if (m = line.match(/(^[^\s]+)\s/)) then
        disks.push(m[1])
      end
    }
    #Create monitrc file
    monitrc = 
      "set daemon 60\n" +
      "set logfile /var/log/monit.log\n";
    count = 1
    disks.each {|disk|
      monitrc += 
        "check device disk#{count} with path #{disk}\n" +
        "  if space usage > #{disk_threshold} then exec \"/etc/monit/slack.sh\" "+
        "else if succeeded then exec \"/etc/monit/slack.sh\"\n"
      count += 1
    }

    sh "sudo cp -f /etc/monit/monitrc /etc/monit/monitrc.`date +%Y%m%d%H%M%S`"
    Tempfile.create("opendax") do |f|
      puts f.path
      f.write(monitrc)
      sh "sudo mv -f #{f.path} /etc/monit/monitrc"
      sh "sudo chown root.root /etc/monit/monitrc"
      sh "sudo chmod 600 /etc/monit/monitrc"
    end

    slack_sh =
      "#!/bin/bash\n\n"+
      '/usr/bin/curl -X POST -s --data-urlencode '+
      '"payload={\"text\":\"$MONIT_HOST - $MONIT_SERVICE - $MONIT_DESCRIPTION\"}" '+
      "#{slack_webhook_url}"

    sh "sudo touch /etc/monit/slack.sh"
    sh "sudo cp -f /etc/monit/slack.sh /etc/monit/slack.sh.`date +%Y%m%d%H%M%S`"
    Tempfile.create("opendax") do |f|
      puts f.path
      f.write(slack_sh)
      sh "sudo mv -f #{f.path} /etc/monit/slack.sh"
      sh "sudo chown root.root /etc/monit/slack.sh"
      sh "sudo chmod 700 /etc/monit/slack.sh"
    end
  
    sh "sudo monit -t"
    sh "sudo service monit restart"

    puts "=== /etc/monitrc:"
    puts monitrc

  end
end
