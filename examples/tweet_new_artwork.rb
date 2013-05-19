require File.expand_path(File.join(File.dirname(__FILE__), 'artsy_config.rb'))
require File.expand_path(File.join(File.dirname(__FILE__), 'twitter_auth.rb'))

Artsy::Client.authenticate!

Artsy::Client.recently_published_artworks.each do |artwork|
  puts artwork
  next unless artwork.can_share_image
  begin
    Twitter.update("#{artwork}\nhttp://artsy.net/artwork/#{artwork.id}")
  rescue Twitter::Error::Forbidden => e
    # duplicate status or too long
    puts e.message
  end
  break # only tweet one work
end
