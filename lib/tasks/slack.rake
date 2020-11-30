require 'net/http'

namespace :slack do

  desc 'Send message to slack'
  task :msg, [:text] do |_, args|
    if (args.text.nil?) then
      puts "Specify message."
      next
    end
    webhook_url = @config['slack']['webhook_url']
    uri = URI.parse(webhook_url)
    payload = {
      text: "#{args.text}"
    }
    Net::HTTP.post_form(uri, { payload: payload.to_json })
    puts "Sent to slack:#{args.text}"
  end

end
