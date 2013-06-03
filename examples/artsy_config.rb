require 'artsy-client'

Artsy::Client.configure do |config|
  config.logger = Logger.new(STDOUT)
  config.logger.level = Logger::INFO
  config.endpoint = "http://artsy.net"
end
