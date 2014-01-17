require File.expand_path(File.join(File.dirname(__FILE__), 'artsy_config.rb'))
require File.expand_path(File.join(File.dirname(__FILE__), 'twitter_client.rb'))
require File.expand_path(File.join(File.dirname(__FILE__), 'smart_truncate.rb'))
require File.expand_path(File.join(File.dirname(__FILE__), 'geocoder_config.rb'))

near_regex = /show[s]? (near|in) (.*)/i

STDOUT.write "Retrieving show requests ... "
show_requests = Twitter.client.mentions_timeline.sort_by { |status| status.id }.select do |status|
  ! status.in_reply_to_status_id? && status.full_text =~ near_regex
end
puts show_requests.count

if show_requests.count > 0
  # recently tweeted replies
  STDOUT.write "Retrieving recent replies ... "
  recent_replies = Twitter.client.user_timeline.map do |status|
    status.in_reply_to_status_id
  end.flatten
  puts recent_replies.count

  Artsy::Client.authenticate!

  show_requests.each do |status|
    puts status.full_text

    if recent_replies.include?(status.id)
      puts " already replied, skipping"
      next
    end

    location = status.full_text.match(near_regex).captures.last
    next unless location
    puts " looking for a show near #{location}:"
    geo = Geocoder.search(location)
    geo = geo.first if geo
    unless geo
      puts "  ERROR: geocoder failed to find location."
      next
    end
    coordinates = geo.coordinates ? { lat: geo.coordinates[0], lng: geo.coordinates[1] } : nil
    unless coordinates
      puts "  ERROR: geocoder failed to map coordinates."
      next
    end
    puts "  #{coordinates}"

    status_nickname = "@#{status.user.screen_name}"

    Artsy::Client.shows(near: "#{coordinates[:lat]},#{coordinates[:lng]}", published_with_eligible_artworks: true, size: 1, status: :running).each do |show|
      show_info = [ show.name, show.partner, show.where, show.when ].compact.join(", ")
      show_info = [ smart_truncate(show.name, 24), show.partner, show.where, show.when ].compact.join(", ") if show_info.length >= Twitter::TWEET_LIMIT_WITHOUT_A_LINK
      show_info = smart_truncate(show_info.to_s, Twitter::TWEET_LIMIT_WITHOUT_A_LINK - status_nickname.length - 1)

      url = "http://artsy.net/show/#{show.id}"
      puts "   => #{[status_nickname, show_info, url].compact.join(' ')}"

      Twitter.client.update("#{status_nickname} #{show_info}\n#{url}", in_reply_to_status_id: status.id)
    end
  end
end

