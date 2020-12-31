
require_relative '../dockerconf/renderer'
require_relative '../dockerconf/util'

namespace :render do

  desc 'Render configuration and compose files and keys'
  task :config do
    if (!Dockerconf::Util::check_hostname_and_status) then
      Dockerconf::Util::show_command_status
      next
    end
    # Must be chown $USER beforehand becuase can't overwrite 
    #unless (File.exist?("config/bitcoin.conf")) then
    #  sh "touch config/bitcoin.conf"
    #end
    #sh "sudo chown #{ENV['USER']} config/bitcoin.conf"
    renderer = Dockerconf::Renderer.new
    renderer.render
    Dockerconf::Util::show_command_status
  end

end
