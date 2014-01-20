require File.expand_path(File.join(File.dirname(__FILE__), 'artsy_config.rb'))
require File.expand_path(File.join(File.dirname(__FILE__), 'twitter_client.rb'))
require File.expand_path(File.join(File.dirname(__FILE__), 'smart_truncate.rb'))
require File.expand_path(File.join(File.dirname(__FILE__), 'geocoder_config.rb'))

near_regex = /(near|in) (.*)/i

# Makes sure show info can fit with other optional tweet text
def format_show_info(show, status_nickname, included_text = '')
  show_info = [ show.name, show.partner, show.where, show.when ].compact.join(", ")
  show_info = [ smart_truncate(show.name, 24), show.partner, show.where, show.when ].compact.join(", ") if show_info.length >= Twitter::TWEET_LIMIT_WITHOUT_A_LINK
  smart_truncate(show_info.to_s, Twitter::TWEET_LIMIT_WITHOUT_A_LINK - status_nickname.length - included_text.length - 1)
end

# Checks if this was already tweeted
def already_tweeted?(user_timeline, show_info)
  user_timeline.detect { |tweet| tweet.reply? && tweet.full_text.include?(show_info) }
end

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
        Twitter.client.update("#{status_nickname} Sorry, I don't know where #{smart_truncate(location, 24)} is :(", in_reply_to_status_id: status.id)
        next
      end
      coordinates = geo.coordinates ? { lat: geo.coordinates[0], lng: geo.coordinates[1] } : nil
      unless coordinates
        puts "  ERROR: geocoder failed to map coordinates."
        Twitter.client.update("#{status_nickname} Sorry, I don't know where #{smart_truncate(location, 24)} is :(", in_reply_to_status_id: status.id)
        next
      end
      puts "  #{coordinates}"

      show_info = nil
      Artsy::Client.shows(near: "#{coordinates[:lat]},#{coordinates[:lng]}", published_with_eligible_artworks: true, status: :running).each do |show|
        url = "http://artsy.net/show/#{show.id}"
        show_info = format_show_info(show, status_nickname)

        if already_tweeted?(user_timeline, show_info)
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
        # No shows found
        shows = Artsy::Client.shows(published_with_eligible_artworks: true, status: :running)
        shows.each do |show|
          url = "http://artsy.net/show/#{show.id}"
          show_info = format_show_info(show, status_nickname, 'Sorry, no shows found near there, but check out ')
          if already_tweeted?(user_timeline, show_info)
            puts "   skipping #{[status_nickname, show_info, url].compact.join(' ')}"
            next
          end

          puts " => No shows found, instead tweeting #{[status_nickname, show_info, url].compact.join(' ')}"
          show_info = "Sorry, no shows found near there, but check out #{show_info}\n#{url}"
          Twitter.client.update("#{status_nickname} #{show_info}", in_reply_to_status_id: status.id)
          break
        end
      end

    rescue Exception => e
      puts "ERROR: #{e.message}"
      puts e.backtrace
    end
  end
end

