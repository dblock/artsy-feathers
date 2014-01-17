require 'geocoder'

api_key = ENV['GEOCODER_API_KEY']
if api_key
  Geocoder.configure(lookup: :mapquest, timeout: 3, api_key: api_key)
else
  Geocoder.configure(lookup: :google, timeout: 3)
end
