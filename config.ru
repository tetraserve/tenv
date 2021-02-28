#\ -s Puma --host 0.0.0.0 -p 1337 -E production

require_relative 'lib/dockerconf/webhook'

run Webhook
