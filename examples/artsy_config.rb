require 'artsy-client'

Artsy::Client.configure do |config|
  config.logger = Logger.new(STDOUT)
  config.logger.level = Logger::DEBUG
  config.endpoint = "http://artsyapi.com"
end