require 'twitter'

module Twitter

  # links count 22 characters, see https://dev.twitter.com/docs/faq#5810 + two CR/LFs
  TWEET_LIMIT_WITHOUT_A_LINK = 140 - 22 - 3

  def self.client
    @client ||= begin
      Twitter::REST::Client.new do |config|
        config.consumer_key = ENV['TWITTER_CONSUMER_KEY']
        config.consumer_secret = ENV['TWITTER_CONSUMER_SECRET']
        config.access_token = ENV['TWITTER_OAUTH_TOKEN']
        config.access_token_secret = ENV['TWITTER_OAUTH_TOKEN_SECRET']
      end
    end
  end
end
