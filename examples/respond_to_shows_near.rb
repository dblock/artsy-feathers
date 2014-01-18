require File.expand_path(File.join(File.dirname(__FILE__), 'artsy_config.rb'))
require File.expand_path(File.join(File.dirname(__FILE__), 'twitter_client.rb'))
require File.expand_path(File.join(File.dirname(__FILE__), 'smart_truncate.rb'))
require File.expand_path(File.join(File.dirname(__FILE__), 'geocoder_config.rb'))

near_regex = /(near|in) (.*)/i

STDOUT.write "Retrieving show requests ... "
show_requests = Twitter.client.mentions_timeline.sort_by { |status| status.id }.select do |status|
  ! status.in_reply_to_status_id? && status.full_text =~ near_regex
end
puts show_requests.count

if show_requests.count > 0
  user_timeline = Twitter.client.user_timeline.to_a

  # recently tweeted replies
  STDOUT.write "Retrieving recent replies ... "
  recent_replies = user_timeline.map do |status|
    status.in_reply_to_status_id
  end.flatten
  puts recent_replies.count

  Artsy::Client.authenticate!

  show_requests.each do |status|
    begin
      puts status.full_text

      if recent_replies.include?(status.id)
        puts " already replied, skipping"
        next
      end

      status_nickname = "@#{status.user.screen_name}"

      location = status.full_text.match(near_regex).captures.last
      next unless location
      puts " looking for a show near #{location}:"
      geo = Geocoder.search(location)
      geo = geo.first if geo
      unless geo
        puts "  ERROR: geocoder failed to find location."
        Twitter.client.update("#{status_nickname} Sorry, I don't know where #{location} is :(", in_reply_to_status_id: status.id)
        next
      end
      coordinates = geo.coordinates ? { lat: geo.coordinates[0], lng: geo.coordinates[1] } : nil
      unless coordinates
        puts "  ERROR: geocoder failed to map coordinates."
        Twitter.client.update("#{status_nickname} Sorry, I don't know where #{location} is :(", in_reply_to_status_id: status.id)
        next
      end
      puts "  #{coordinates}"

      show_info = nil
      Artsy::Client.shows(near: "#{coordinates[:lat]},#{coordinates[:lng]}", published_with_eligible_artworks: true, status: :running).each do |show|
        url = "http://artsy.net/show/#{show.id}"

        show_info = [ show.name, show.partner, show.where, show.when ].compact.join(", ")
        show_info = [ smart_truncate(show.name, 24), show.partner, show.where, show.when ].compact.join(", ") if show_info.length >= Twitter::TWEET_LIMIT_WITHOUT_A_LINK
        show_info = smart_truncate(show_info.to_s, Twitter::TWEET_LIMIT_WITHOUT_A_LINK - status_nickname.length - 1)

        # did we tweet this show already as a reply?
        previous_tweet = user_timeline.detect do |tweet|
          tweet.reply? && tweet.full_text.include?(show_info)
        end
        if previous_tweet
          puts "   skipping #{[status_nickname, show_info, url].compact.join(' ')}"
          next
        end

        puts "   => #{[status_nickname, show_info, url].compact.join(' ')}"
        show_info = "#{show_info}\n#{url}"
        break
      end

      if show_info
        Twitter.client.update("#{status_nickname} #{show_info}", in_reply_to_status_id: status.id)
      else
        Twitter.client.update("#{status_nickname} Sorry, I didn't find any running or upcoming shows near #{location} :(", in_reply_to_status_id: status.id)
      end
    rescue Exception => e
      puts "ERROR: #{e.message}"
      puts e.backtrace
    end
  end
end

