require File.expand_path(File.join(File.dirname(__FILE__), 'artsy_config.rb'))
require File.expand_path(File.join(File.dirname(__FILE__), 'twitter_client.rb'))
require File.expand_path(File.join(File.dirname(__FILE__), 'smart_truncate.rb'))
require File.expand_path(File.join(File.dirname(__FILE__), 'geocoder_config.rb'))

module Artsy
  module Client
    module API
      module Show
        def shows(options = {})
          objects_from_response(self, Artsy::Client::Domain::Show, :get, "/api/v1/shows", options)
        end
      end
    end
  end
end

module Artsy
  module Client
    module Domain
      class Show
        def artworks(options = {})
          if partner
            @artworks ||= instance.send(:objects_from_response, instance, Artsy::Client::Domain::Artwork, :get, "/api/v1/partner/#{partner.id}/show/#{id}/artworks", options)
          else
            @artworks = []
          end
        end
      end
    end
  end
end

# make a tree of tweets
show_requests = Twitter.client.mentions_timeline.sort_by { |status| status.id }.select do |status|
  ! status.in_reply_to_status_id? && status.full_text =~ /show (near|in) (.*)/i
end

Artsy::Client.authenticate!

# recently tweeted replies
recent_replies = Twitter.client.user_timeline.map do |status|
  status.in_reply_to_status_id
end.flatten

show_requests.each do |status|
  puts status.full_text

  if recent_replies.include?(status.id)
    puts " already replied, skipping"
    next
  end

  location = status.full_text.match(/show (near|in) (.*)/i).captures.last
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

  Artsy::Client.shows(near: "#{coordinates[:lat]},#{coordinates[:lng]}", published_with_eligible_artworks: true, size: 1).reverse.each do |show|
    show_info = [ show.name, show.partner, show.where, show.when ].compact.join(", ")
    show_info = [ smart_truncate(show.name, 24), show.partner, show.where, show.when ].compact.join(", ") if show_info.length >= Twitter::TWEET_LIMIT_WITHOUT_A_LINK
    show_info = smart_truncate(show_info.to_s, Twitter::TWEET_LIMIT_WITHOUT_A_LINK - status_nickname.length - 1)

    url = "http://artsy.net/show/#{show.id}"
    puts "   => #{[status_nickname, show_info, url].compact.join(' ')}"

    Twitter.client.update("#{status_nickname} #{show_info}\n#{url}", in_reply_to_status_id: status.id)
  end
end

