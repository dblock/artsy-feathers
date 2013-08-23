require File.expand_path(File.join(File.dirname(__FILE__), 'artsy_config.rb'))
require File.expand_path(File.join(File.dirname(__FILE__), 'twitter_auth.rb'))
require File.expand_path(File.join(File.dirname(__FILE__), 'smart_truncate.rb'))

# recently tweeted posts
recent_urls = Twitter.user_timeline.map do |status|
  status.urls.map(&:expanded_url)
end.flatten

Artsy::Client.authenticate!

Artsy::Client.featured_posts[:results].reverse.each do |post|

  puts "#{post}"

  url = "http://artsy.net/post/#{post.id}"
  if recent_urls.include?(url)
    puts "  Skipping, already tweeted."
    next
  end

  # links count 22 characters, see https://dev.twitter.com/docs/faq#5810 + two CR/LFs
  post_info = smart_truncate("#{post.title} by #{post.author}", 140 - 22 - 3)
  Twitter.update("#{post_info}\n#{url}")
  break # one at a time

end
