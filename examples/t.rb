require File.expand_path(File.join(File.dirname(__FILE__), 'artsy_config.rb'))
require File.expand_path(File.join(File.dirname(__FILE__), 'twitter_client.rb'))
require File.expand_path(File.join(File.dirname(__FILE__), 'smart_truncate.rb'))
require File.expand_path(File.join(File.dirname(__FILE__), 'geocoder_config.rb'))

module Artsy
  module Client
    module API
      module Show
        include Artsy::Client::API::Parse

        # Retrieves recent shows.
        #
        # @return [Hash]
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

Artsy::Client.authenticate!

[
  {:lat=>46.1983922, :lng=>6.142296099999999},
  {:lat=>40.7143528, :lng=>-74.00597309999999},
  {:lat=>51.51121389999999, :lng=>-0.1198244}
].each do |coordinates|

  puts " #{coordinates}"

  Artsy::Client.shows(near: "#{coordinates[:lat]},#{coordinates[:lng]}", published_with_eligible_artworks: true, size: 1).reverse.each do |show|
    show_info = [ show.name, show.partner, show.where, show.when ].compact.join(", ")
    show_info = [ smart_truncate(show.name, 24), show.partner, show.where, show.when ].compact.join(", ") if show_info.length >= Twitter::TWEET_LIMIT_WITHOUT_A_LINK
    show_info = smart_truncate(show_info.to_s, Twitter::TWEET_LIMIT_WITHOUT_A_LINK)

    show = Artsy::Client::Domain::Show.new(show)
    show.instance = Artsy::Client.instance

    artwork = show.artworks.detect { |a| a.can_share_image }
    if artwork
      url = "http://artsy.net/artwork/#{artwork.id}"
    end

    puts [show_info, url].compact.join("\n")
  end
end
