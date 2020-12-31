# frozen_string_literal: true

require 'openssl'
require 'pathname'
require 'yaml'
require 'base64'

require_relative './renderer_helper'
require_relative './renderer_helper_gcp'
require_relative './renderer_helper_hc'

module Dockerconf
  # Renderer is class for rendering Dockerconf templates.
  class Renderer
    TEMPLATE_PATH = Pathname.new('./templates')


    def render
      @config ||= config
      @utils  ||= utils
      @deploy  ||= deploy

      if (@config['mode'] != "base") then
        begin
        @config['database']['docker_volumes_path'].gsub!(/__HOME__/, ENV['HOME'])
        @config['database']['password'].gsub!(
          /__DB_PASSORD__/, File.read("./config/secrets/db_password.txt").strip)
        @config['pma']['basic_auth'].gsub!(
          /__PMA_AUTH__/, File.read("./config/secrets/pma_auth.txt").strip)
        rescue
          puts "WARN) May be secrets files missing."
        end
      end

      Dir.glob("#{TEMPLATE_PATH}/**/*.erb", File::FNM_DOTMATCH).each do |file|
        if (@config['mode']=='local'||@config['mode']=='sample') then
          if (file.include?('/terraform/')) then
            next
          end
        end
        if (@config['mode']=='base') then
          if (file.include?('/config/')||file.include?('/compose/')) then
            next
          end
        end
        if (file.include?('/terraform_src/')) then
          next
        end
        output_file = template_name(file)
        FileUtils.chmod 0o644, output_file if File.exist?(output_file)
        render_file(file, output_file)
        FileUtils.chmod 0o444, output_file if @config['render_protect']
      end
    end

    def render_file(file, out_file)
      puts "Rendering #{out_file}"
      result = ERB.new(File.read(file), trim_mode: '-').result(binding)
      File.write(out_file, result)
    end

    def ssl_helper(arg)
      @config['ssl']['enabled'] ? arg << 's' : arg
    end

    def template_name(file)
      path = Pathname.new(file)
      out_path = path.relative_path_from(TEMPLATE_PATH).sub('.erb', '')

      File.join('.', out_path)
    end

    def config
      conf = JSON.parse(File.read('./config/render.json'))
      YAML.load_file("./master_config/#{conf['app']}.app.yml")
    end

    def utils
      YAML.load_file('./master_config/utils.yml')
    end

    def deploy
      YAML.load_file('./master_config/deploy.yml')
    end
  end
end
