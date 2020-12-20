
require_relative '../opendax/renderer'
require_relative '../opendax/util'

namespace :render do

  desc 'Render configuration and compose files and keys'
  task :config do
    if (!Opendax::Util::check_hostname_and_status) then
      Opendax::Util::show_command_status
      next
    end
    # Must be chown $USER beforehand becuase can't overwrite 
    #unless (File.exist?("config/bitcoin.conf")) then
    #  sh "touch config/bitcoin.conf"
    #end
    #sh "sudo chown #{ENV['USER']} config/bitcoin.conf"
    renderer = Opendax::Renderer.new
    renderer.render_keys
    renderer.render
    Opendax::Util::show_command_status
  end

end
