module Dockerconf

  class Util

    def self.show_command_status
      conf = JSON.parse(File.read('./config/render.json'))
      puts "Status: r:c[#{conf['app']}], tf:c[#{conf['cloud']}]"
    end

    def self.check_hostname_and_status
      
      host = `hostname`.strip

      # TODO: for special cases
      if (host.include?('something special..')) then
        host = 'special-prd'
      end

      conf = JSON.parse(File.read('./config/render.json'))
      
      if (host.include?('-stg1')) then
        if (conf['app'] != 'stg1') then
          puts "ERROR: Your conf[app] is not stg1"
          return false
        end
      elsif(host.include?('-stg2')) then
        if (conf['app'] != 'stg2') then
          puts "ERROR: Your conf[app] is not stg2"
          return false
        end
      elsif(host.include?('-stg3')) then
        if (conf['app'] != 'stg3') then
          puts "ERROR: Your conf[app] is not stg3"
          return false
        end
      elsif(host.include?('-prd')) then
        if (conf['app'] != 'prd') then
          puts "ERROR: Your conf[app] is not prd"
          return false
        end
      else
        # seems host is local
      end

      true # OK

    end

  end

end