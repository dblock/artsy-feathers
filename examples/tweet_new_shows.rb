require 'artsy-client'
require File.expand_path(File.join(File.dirname(__FILE__), 'twitter_auth.rb'))

Artsy::Client.authenticate!

Artsy::Client.shows[:results].reverse.each do |show|
  puts "#{show}"
  show.artworks.each do |artwork|
    puts " #{artwork}"
    next unless artwork.can_share_image
    begin
      show_info = [ show.partner, show.where, show.when ].compact.join(", ")
      Twitter.update("#{artwork}\n#{show_info}\nhttp://artsy.net/artwork/#{artwork.id}")
      break # one at a time
    rescue Twitter::Error::Forbidden => e
      puts "  ERROR: #{e.message}"
    end
    break # only one work
  end
end
