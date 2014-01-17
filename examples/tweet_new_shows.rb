require File.expand_path(File.join(File.dirname(__FILE__), 'artsy_config.rb'))
require File.expand_path(File.join(File.dirname(__FILE__), 'twitter_client.rb'))
require File.expand_path(File.join(File.dirname(__FILE__), 'smart_truncate.rb'))

# recently tweeted works or shows
recent_urls = Twitter.client.user_timeline.map do |status|
  status.urls.map(&:expanded_url).map(&:to_s)
end.flatten

Artsy::Client.authenticate!

Artsy::Client.shows_feed[:results].reverse.each do |show|

  show_info = [ show.name, show.partner, show.where, show.when ].compact.join(", ")
  show_info = [ smart_truncate(show.name, 24), show.partner, show.where, show.when ].compact.join(", ") if show_info.length >= Twitter::TWEET_LIMIT_WITHOUT_A_LINK
  show_info = smart_truncate(show_info.to_s, Twitter::TWEET_LIMIT_WITHOUT_A_LINK)

  puts show_info

  artwork = show.artworks.detect { |a| a.can_share_image }
  if artwork
    url = "http://artsy.net/artwork/#{artwork.id}"
    if recent_urls.include?(url)
      puts "  Skipping, already tweeted."
      next
    end
  end

  url = "http://artsy.net/show/#{show.id}"
  if recent_urls.include?(url)
    puts "  Skipping, already tweeted."
    next
  end

  Twitter.client.update("#{show_info}\n#{url}")
  break # one at a time

end
