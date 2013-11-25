require 'faker'
require 'stringex'

require File.expand_path(File.join(File.dirname(__FILE__), 'artsy_config.rb'))
require File.expand_path(File.join(File.dirname(__FILE__), 'twitter_client.rb'))

Artsy::Client.authenticate!

# recently tweeted terms
recent_urls = Twitter.client.user_timeline.map do |status|
  status.urls.map(&:expanded_url).map(&:to_s)
end.flatten

# generate a 2-letter semi-random term
term = Faker::Name.first_name[0..1].downcase

tweeted = false
Artsy::Client.autocomplete(term).each do |search_query|
  query = search_query.query.downcase
  puts query
  Artsy::Client.match(search_query.query.downcase, size: 3).each do |match|
    next unless match.object
    next if match.object.respond_to?(:can_share_image) && ! match.object.can_share_image
    url = [ "http://artsy.net", match.model == "profile" ? nil : match.model, match.id ].compact.join("/")
    puts " #{match.object}, #{url}"
    if recent_urls.include?(url)
      puts "  Skipping, already tweeted."
      next
    end
    Twitter.client.update("#{match.object}\n#{url}")
    tweeted = true
    break
  end
  break if tweeted
end
