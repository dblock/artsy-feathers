require File.expand_path(File.join(File.dirname(__FILE__), 'artsy_config.rb'))
require File.expand_path(File.join(File.dirname(__FILE__), 'twitter_auth.rb'))
require File.expand_path(File.join(File.dirname(__FILE__), 'smart_truncate.rb'))

# recently tweeted works or shows
recent_urls = Twitter.user_timeline.map do |status|
  status.urls.map(&:expanded_url)
end.flatten

Artsy::Client.authenticate!

Artsy::Client.shows[:results].reverse.each do |show|

  puts "#{show}"

  artwork = show.artworks.detect { |a| a.can_share_image }
  url = "http://artsy.net/artwork/#{artwork.id}"
  if recent_urls.include?(url)
    puts "  Skipping, already tweeted."
    next
  end

  url = "http://artsy.net/show/#{show.id}"
  if recent_urls.include?(url)
    puts "  Skipping, already tweeted."
    next
  end

  show_info = [ show.partner, show.where, show.when ].compact.join(", ")

  # links count 22 characters, see https://dev.twitter.com/docs/faq#5810 + two CR/LFs
  show_info = smart_truncate(show_info.to_s, 140 - 22 - 3)
  Twitter.update("#{show_info}\n#{url}")
  break # one at a time

end
