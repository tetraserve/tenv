module Opendax

  class RendererHelperGcp

    def self.connstr(user)
      return <<"EOS"
      connection {
        host        = self.network_interface[0].access_config[0].nat_ip
        type        = "ssh"
        user        = "#{user}"
        private_key = file(var.ssh_private_key)
      }
EOS
    end

    def self.provisioner_local_exec(command)
      return <<"EOS"
    provisioner "local-exec" {
      command = #{command}
    }      
EOS
    end

    def self.provisioner_remote_exec(user, body)
      connstr = self::connstr(user)
      return <<"EOS"
    provisioner "remote-exec" {
      #{body}
      #{connstr}
    }
EOS
    end

    def self.provisioner_file(user, src, dest)
      connstr = self::connstr(user)
      return <<"EOS"
    provisioner "file" {
      source = #{src}
      destination = #{dest}
      #{connstr}
    }
EOS
    end

  end

end
